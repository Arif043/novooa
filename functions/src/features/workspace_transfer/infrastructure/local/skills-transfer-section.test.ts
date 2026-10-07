import assert from "node:assert/strict";
import {createWriteStream} from "node:fs";
import {mkdir, writeFile} from "node:fs/promises";
import path from "node:path";
import {finished} from "node:stream/promises";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {DirectorySkillStore} from "../../../skills/infrastructure/local/directory-skill-store.js";
import {TransferCategorySelection, type TransferCategory} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {SkillsTransferSection} from "./skills-transfer-section.js";
import {SQLiteTransferImportStore} from "./sqlite-transfer-import-store.js";
import {type SQLiteTransferSectionImporter} from "./sqlite-transfer-section-importer.js";
import {temporaryDirectory} from "./workspace-transfer-test-support.js";

const skillMd = (name: string, text = "Anleitung") => `---\nname: ${name}\ndescription: Beschreibung von ${name}\n---\n${text}\n`;

async function skillStore(t: TestContext, skills: Record<string, Record<string, string | Uint8Array>> = {}): Promise<DirectorySkillStore> {
  const root = path.join(await temporaryDirectory(t), "skills");
  for (const [name, files] of Object.entries(skills)) {
    for (const [relative, content] of Object.entries(files)) {
      await mkdir(path.dirname(path.join(root, name, relative)), {recursive: true});
      await writeFile(path.join(root, name, relative), content);
    }
  }
  return new DirectorySkillStore(root);
}

async function exportSkills(t: TestContext, store: DirectorySkillStore, categories: TransferCategory[] = ["skills"]): Promise<string> {
  const archivePath = path.join(await temporaryDirectory(t), "export.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(archivePath)));
  await new ExportWorkspace([new SkillsTransferSection(store)]).execute({
    teamId: "team-1", selection: TransferCategorySelection.from(categories), writer,
  });
  writer.finish();
  await written;
  return archivePath;
}

async function importSkills(t: TestContext, target: DirectorySkillStore, archivePath: string, extra: SQLiteTransferSectionImporter[] = [], categories: TransferCategory[] = ["skills"]) {
  const store = new SQLiteTransferImportStore(await runtimeTestDatabase(t), [new SkillsTransferSection(target), ...extra]);
  return new ImportWorkspace(new InspectWorkspaceImport(), store).execute({
    teamId: "team-2", selection: TransferCategorySelection.from(categories), reader: new FflateTransferArchiveReader(archivePath),
  });
}

async function rebuilt(t: TestContext, archivePath: string, change: (json: Record<string, unknown>) => Record<string, unknown>, keepBlobs = true): Promise<string> {
  const reader = new FflateTransferArchiveReader(archivePath);
  const target = path.join(await temporaryDirectory(t), "geaendert.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(target)));
  await writer.addJson("data/skills.json", change(await reader.json("data/skills.json") as Record<string, unknown>));
  await writer.addJson("manifest.json", await reader.json("manifest.json"));
  const payload = await reader.json("data/skills.json") as {skills: Array<{name: string; files: Array<{path: string}>}>};
  const names = new Set(payload.skills.flatMap((skill) => skill.files.map((file) => `blobs/skills/${skill.name}/${file.path}`)));
  if (keepBlobs) {
    await reader.forEachBlob(names, async (name, content) => writer.addBlob(name, (async function* () { yield content; })()));
  }
  writer.finish();
  await written;
  return target;
}

test("exports every skill folder with all files and imports it into another skills folder", async (t) => {
  const binary = new Uint8Array([0, 1, 2, 255]);
  const source = await skillStore(t, {
    pdf: {"SKILL.md": skillMd("pdf"), "references/REFERENCE.md": "Referenz", "assets/logo.bin": binary, "data/daten.json": "{\"a\":1}"},
    review: {"SKILL.md": skillMd("review")},
  });
  const archivePath = await exportSkills(t, source);
  const target = await skillStore(t);

  const counts = await importSkills(t, target, archivePath);

  assert.deepEqual(counts, {skills: 2});
  assert.deepEqual((await target.list()).map((skill) => [skill.name, skill.fileCount]), [["pdf", 4], ["review", 1]]);
  const files = await target.readFiles("pdf");
  assert.deepEqual(files.map((file) => file.path).sort(), ["SKILL.md", "assets/logo.bin", "data/daten.json", "references/REFERENCE.md"]);
  assert.deepEqual([...files.find((file) => file.path === "assets/logo.bin")!.bytes], [...binary]);
  assert.equal(new TextDecoder().decode(files.find((file) => file.path === "data/daten.json")!.bytes), "{\"a\":1}");
});

test("the manifest counts the exported skills", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {a: {"SKILL.md": skillMd("a")}, b: {"SKILL.md": skillMd("b")}}));

  const manifest = await new FflateTransferArchiveReader(archivePath).json("manifest.json") as {categories: string[]; counts: Record<string, number>};

  assert.deepEqual(manifest.categories, ["skills"]);
  assert.deepEqual(manifest.counts, {skills: 2});
});

test("an empty skills folder exports and imports as zero skills", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t));
  const target = await skillStore(t, {vorhanden: {"SKILL.md": skillMd("vorhanden")}});

  assert.deepEqual(await importSkills(t, target, archivePath), {skills: 0});
  assert.deepEqual((await target.list()).map((skill) => skill.name), ["vorhanden"], "nothing is deleted");
});

test("merging replaces a skill of the same name completely and keeps the others", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {pdf: {"SKILL.md": skillMd("pdf", "Neu")}}));
  const target = await skillStore(t, {
    pdf: {"SKILL.md": skillMd("pdf", "Alt"), "references/alt.md": "veraltet"},
    anderer: {"SKILL.md": skillMd("anderer")},
  });

  await importSkills(t, target, archivePath);

  const files = await target.readFiles("pdf");
  assert.deepEqual(files.map((file) => file.path), ["SKILL.md"], "old extra files are gone");
  assert.match(new TextDecoder().decode(files[0].bytes), /Neu/);
  assert.deepEqual((await target.list()).map((skill) => skill.name), ["anderer", "pdf"]);
});

test("a failure in a later category restores replaced skills and removes new ones", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {
    pdf: {"SKILL.md": skillMd("pdf", "Neu"), "references/neu.md": "x"}, frisch: {"SKILL.md": skillMd("frisch")},
  }));
  const target = await skillStore(t, {pdf: {"SKILL.md": skillMd("pdf", "Alt"), "references/alt.md": "behalten"}});
  const failing: SQLiteTransferSectionImporter = {
    category: "tasks",
    stage: async () => ({count: 1, commit: async () => { throw new Error("Aufgaben kaputt"); }, rollback: async () => undefined}),
  };
  const withTasks = await rebuiltManifest(t, archivePath, ["skills", "tasks"]);

  await assert.rejects(importSkills(t, target, withTasks, [failing], ["skills", "tasks"]), /Aufgaben kaputt/);

  assert.deepEqual((await target.list()).map((skill) => skill.name), ["pdf"], "the new skill was removed");
  assert.deepEqual((await target.readFiles("pdf")).map((file) => file.path).sort(), ["SKILL.md", "references/alt.md"]);
  assert.equal(new TextDecoder().decode((await target.readFiles("pdf")).find((file) => file.path === "references/alt.md")!.bytes), "behalten");
});

async function rebuiltManifest(t: TestContext, archivePath: string, categories: string[]): Promise<string> {
  const reader = new FflateTransferArchiveReader(archivePath);
  const target = path.join(await temporaryDirectory(t), "mit-aufgaben.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(target)));
  await writer.addJson("data/skills.json", await reader.json("data/skills.json"));
  await writer.addJson("data/tasks.json", {tasks: []});
  const manifest = await reader.json("manifest.json") as {counts: object};
  await writer.addJson("manifest.json", {...manifest, categories, counts: {...manifest.counts, tasks: 1}});
  const payload = await reader.json("data/skills.json") as {skills: Array<{name: string; files: Array<{path: string}>}>};
  await reader.forEachBlob(
    new Set(payload.skills.flatMap((skill) => skill.files.map((file) => `blobs/skills/${skill.name}/${file.path}`))),
    async (name, content) => writer.addBlob(name, (async function* () { yield content; })()),
  );
  writer.finish();
  await written;
  return target;
}

test("an export with missing file contents is rejected before anything is written", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {pdf: {"SKILL.md": skillMd("pdf")}}));
  const target = await skillStore(t);

  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, (json) => json, false)), InvalidTransferArchiveError);

  assert.deepEqual(await target.list(), []);
});

test("unsafe paths, a missing SKILL.md and duplicate skills are rejected as an invalid export", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {pdf: {"SKILL.md": skillMd("pdf")}}));
  const target = await skillStore(t);
  const withFiles = (files: string[], name = "pdf") => ({skills: [{name, files: files.map((file) => ({path: file}))}]});

  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => withFiles(["SKILL.md", "../ausbruch.txt"]))), InvalidTransferArchiveError);
  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => withFiles(["SKILL.md", "/etc/passwd"]))), InvalidTransferArchiveError);
  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => withFiles(["README.md"]))), InvalidTransferArchiveError);
  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => ({skills: [...withFiles(["SKILL.md"]).skills, ...withFiles(["SKILL.md"]).skills]}))), /mehrfach/);
  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => ({skills: "kaputt"}))), InvalidTransferArchiveError);

  assert.deepEqual(await target.list(), []);
});

test("skill folders with unsafe names cannot be written outside the skills folder", async (t) => {
  const archivePath = await exportSkills(t, await skillStore(t, {pdf: {"SKILL.md": skillMd("pdf")}}));
  const target = await skillStore(t);

  await assert.rejects(importSkills(t, target, await rebuilt(t, archivePath, () => ({skills: [{name: "../ausbruch", files: [{path: "SKILL.md"}]}]}))));

  assert.deepEqual(await target.list(), []);
});
