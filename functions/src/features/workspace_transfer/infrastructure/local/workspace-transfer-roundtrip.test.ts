import {eq} from "drizzle-orm";
import assert from "node:assert/strict";
import {createWriteStream} from "node:fs";
import {readdir, readFile, writeFile} from "node:fs/promises";
import path from "node:path";
import {finished} from "node:stream/promises";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {documentCollections, documents, fileFolders, files, fileVersions, knowledgeNotes, tasks, teams} from "../../../../db/schema.js";
import {currentFilesQuery} from "../../../files/infrastructure/local/local-file-queries.js";
import {TransferCategorySelection, type TransferCategory} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {SqliteDataTransferSection} from "./sqlite-data-transfer-section.js";
import {SqliteFilesTransferImporter} from "./sqlite-files-transfer-importer.js";
import {SqliteKnowledgeTransferSection} from "./sqlite-knowledge-transfer-section.js";
import {SqliteTasksTransferSection} from "./sqlite-tasks-transfer-section.js";
import {SqliteTransferImportStore} from "./sqlite-transfer-import-store.js";
import {exportArchive, sampleStoragePath, seedWorkspace, temporaryDirectory} from "./workspace-transfer-test-support.js";

const allCategories: TransferCategory[] = ["files", "data", "knowledge", "tasks"];

async function* chunksOf(content: Uint8Array): AsyncIterable<Uint8Array> {
  yield content;
}

async function exportedSample(t: TestContext, categories = allCategories) {
  const source = await runtimeTestDatabase(t);
  const sourceRoot = await temporaryDirectory(t);
  await seedWorkspace(source, sourceRoot);
  const archivePath = path.join(await temporaryDirectory(t), "export.zip");
  await exportArchive(source, sourceRoot, categories, archivePath);
  return {source, sourceRoot, archivePath};
}

async function targetWorkspace(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Ziel", owner_uid: "user-2"});
  return {database, runtimeRoot: await temporaryDirectory(t)};
}

async function importInto(target: Awaited<ReturnType<typeof targetWorkspace>>, archivePath: string,
  teamId: string, categories = allCategories) {
  const sections = [new SqliteDataTransferSection(target.database), new SqliteKnowledgeTransferSection(target.database),
    new SqliteTasksTransferSection(target.database)];
  const store = new SqliteTransferImportStore(target.database, [new SqliteFilesTransferImporter(target.runtimeRoot), ...sections]);
  return new ImportWorkspace(new InspectWorkspaceImport(), store).execute({
    teamId, selection: TransferCategorySelection.from(categories), reader: new FflateTransferArchiveReader(archivePath),
  });
}

test("exports a manifest with counts per selected category", async (t) => {
  const {archivePath} = await exportedSample(t, ["files", "tasks"]);
  const manifest = await new InspectWorkspaceImport().execute(new FflateTransferArchiveReader(archivePath));
  assert.deepEqual(manifest.categories, ["files", "tasks"]);
  assert.deepEqual(manifest.counts, {files: 1, tasks: 1});
  assert.equal(manifest.sourceTeamId, "team-1");
});

test("imports all categories into another team and rewrites file paths", async (t) => {
  const {archivePath} = await exportedSample(t);
  const target = await targetWorkspace(t);
  const imported = await importInto(target, archivePath, "team-2");
  assert.deepEqual(imported, {files: 1, data: 1, knowledge: 1, tasks: 1});
  const file = await currentFilesQuery(target.database).where(eq(files.id, "file-1")).get();
  assert.equal(file?.team_id, "team-2");
  assert.equal(file?.storage_path, "teams/team-2/files/file-1/versions/version-1/angebot.txt");
  assert.equal(await readFile(path.join(target.runtimeRoot, file?.storage_path ?? ""), "utf8"), "Hallo");
  const task = await target.database.select().from(tasks).where(eq(tasks.id, "task-1")).get();
  assert.match(task?.graph_json ?? "", /teams\/team-2\/files\/file-1/);
  assert.equal((await target.database.select().from(fileFolders)).length, 2);
  assert.equal((await target.database.select().from(knowledgeNotes)).length, 1);
});

test("imports only the requested categories", async (t) => {
  const {archivePath} = await exportedSample(t);
  const target = await targetWorkspace(t);
  assert.deepEqual(await importInto(target, archivePath, "team-2", ["knowledge"]), {knowledge: 1});
  assert.equal((await target.database.select().from(tasks)).length, 0);
  assert.equal((await target.database.select().from(files)).length, 0);
});

test("merges by id: overwrites existing rows and keeps unrelated ones", async (t) => {
  const {source, sourceRoot, archivePath} = await exportedSample(t);
  await source.update(tasks).set({title: "Lokal geändert"}).where(eq(tasks.id, "task-1"));
  await source.insert(tasks).values({id: "task-local", team_id: "team-1", title: "Nur lokal", graph_json: "{}",
    created_by_uid: "user-1"});
  await importInto({database: source, runtimeRoot: sourceRoot}, archivePath, "team-1", ["tasks"]);
  const rows = await source.select().from(tasks).where(eq(tasks.team_id, "team-1"));
  assert.deepEqual(rows.map((row) => row.title).sort(), ["Angebot prüfen", "Nur lokal"]);
});

test("merges documents into an existing collection with the same name", async (t) => {
  const {archivePath} = await exportedSample(t, ["data"]);
  const target = await targetWorkspace(t);
  await target.database.insert(documentCollections).values({id: "existing", team_id: "team-2", display_name: "Kunden"});
  await importInto(target, archivePath, "team-2", ["data"]);
  const document = await target.database.select().from(documents).where(eq(documents.id, "doc-1")).get();
  assert.equal(document?.collection_id, "existing");
  assert.equal((await target.database.select().from(documentCollections)).length, 1);
});

test("imports nothing and removes copied files when one category is invalid", async (t) => {
  const {archivePath} = await exportedSample(t, ["files"]);
  const reader = new FflateTransferArchiveReader(archivePath);
  const brokenPath = path.join(await temporaryDirectory(t), "kaputt.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(brokenPath)));
  await writer.addJson("data/files.json", await reader.json("data/files.json"));
  await writer.addJson("data/tasks.json", {tasks: [{id: "ohne-pflichtfelder"}]});
  await reader.forEachBlob(new Set([`blobs/${sampleStoragePath}`]), (name, content) => writer.addBlob(name, chunksOf(content)));
  await writer.addJson("manifest.json", {...await reader.json("manifest.json") as object, categories: ["files", "tasks"]});
  writer.finish();
  await written;
  const target = await targetWorkspace(t);
  await assert.rejects(importInto(target, brokenPath, "team-2", ["files", "tasks"]), InvalidTransferArchiveError);
  assert.equal((await target.database.select().from(files)).length, 0);
  assert.deepEqual(await readdir(target.runtimeRoot, {recursive: true}).then((entries) => entries.filter((entry) => entry.endsWith(".txt"))), []);
});

test("rejects files that are not a novooa export", async (t) => {
  const archivePath = path.join(await temporaryDirectory(t), "fremd.zip");
  await writeFile(archivePath, "kein zip");
  const inspect = new InspectWorkspaceImport().execute(new FflateTransferArchiveReader(archivePath));
  await assert.rejects(inspect, InvalidTransferArchiveError);
});


test("file exports contain metadata only in versions and can be imported repeatedly", async (t) => {
  const {archivePath} = await exportedSample(t, ["files"]);
  const payload = await new FflateTransferArchiveReader(archivePath).json("data/files.json") as {
    files: Array<Record<string, unknown>>; versions: Array<Record<string, unknown>>;
  };
  for (const name of ["contentType", "sizeBytes", "storagePath"]) {
    assert.ok(!(name in payload.files[0]));
    assert.ok(name in payload.versions[0]);
  }
  const target = await targetWorkspace(t);
  await importInto(target, archivePath, "team-2", ["files"]);
  await importInto(target, archivePath, "team-2", ["files"]);
  assert.equal((await target.database.select().from(files)).length, 1);
  assert.equal((await target.database.select().from(fileVersions)).length, 1);
});

test("file imports reject ownership conflicts without modifying another team's file", async (t) => {
  const {source, sourceRoot, archivePath} = await exportedSample(t, ["files"]);
  await source.insert(teams).values({id: "team-2", name: "Andere", owner_uid: "user-2"});
  await assert.rejects(importInto({database: source, runtimeRoot: sourceRoot}, archivePath, "team-2", ["files"]),
    InvalidTransferArchiveError);
  const file = await currentFilesQuery(source).where(eq(files.id, "file-1")).get();
  assert.equal(file?.team_id, "team-1");
  assert.equal(file?.current_version_id, "version-1");
  assert.equal(file?.size_bytes, 5);
});
