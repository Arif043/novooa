import assert from "node:assert/strict";
import {createWriteStream} from "node:fs";
import path from "node:path";
import {finished} from "node:stream/promises";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {teams} from "../../../../db/schema.js";
import {SqliteEmployeeStore} from "../../../employees/infrastructure/local/sqlite-employee-store.js";
import {TransferCategorySelection} from "../../domain/entities/transfer-category.js";
import {InvalidTransferArchiveError} from "../../domain/entities/transfer-errors.js";
import {ExportWorkspace} from "../../domain/usecases/export-workspace.js";
import {ImportWorkspace} from "../../domain/usecases/import-workspace.js";
import {InspectWorkspaceImport} from "../../domain/usecases/inspect-workspace-import.js";
import {FflateTransferArchiveReader} from "../zip/fflate-transfer-archive-reader.js";
import {FflateTransferArchiveWriter} from "../zip/fflate-transfer-archive-writer.js";
import {SqliteEmployeesTransferSection} from "./employees-transfer-section.js";
import {SqliteTransferImportStore} from "./sqlite-transfer-import-store.js";
import {temporaryDirectory} from "./workspace-transfer-test-support.js";

async function exported(t: TestContext, database: Awaited<ReturnType<typeof runtimeTestDatabase>>): Promise<string> {
  const archivePath = path.join(await temporaryDirectory(t), "export.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(archivePath)));
  await new ExportWorkspace([new SqliteEmployeesTransferSection(database)]).execute({
    teamId: "team-1", selection: TransferCategorySelection.from(["employees"]), writer,
  });
  writer.finish();
  await written;
  return archivePath;
}

async function target(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Ziel", owner_uid: "user-2"});
  return {database, store: new SqliteEmployeeStore(database)};
}

async function importInto(database: Awaited<ReturnType<typeof runtimeTestDatabase>>, archivePath: string) {
  const store = new SqliteTransferImportStore(database, [new SqliteEmployeesTransferSection(database)]);
  return new ImportWorkspace(new InspectWorkspaceImport(), store).execute({
    teamId: "team-2", selection: TransferCategorySelection.from(["employees"]), reader: new FflateTransferArchiveReader(archivePath),
  });
}

async function rebuilt(t: TestContext, archivePath: string, employees: unknown): Promise<string> {
  const reader = new FflateTransferArchiveReader(archivePath);
  const out = path.join(await temporaryDirectory(t), "geaendert.zip");
  const writer = new FflateTransferArchiveWriter();
  const written = finished(writer.output.pipe(createWriteStream(out)));
  await writer.addJson("data/employees.json", {employees});
  await writer.addJson("manifest.json", await reader.json("manifest.json"));
  writer.finish();
  await written;
  return out;
}

test("exports employees with constraint and skill names and imports them into another team", async (t) => {
  const source = await runtimeTestDatabase(t);
  const sourceStore = new SqliteEmployeeStore(source);
  await sourceStore.create("team-1", {name: "Rezeption", constraint: "Sei freundlich.", skills: ["pdf", "mails"]});
  await sourceStore.create("team-1", {name: "Buchhaltung", constraint: "", skills: []});
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);

  const counts = await importInto(database, archivePath);

  assert.deepEqual(counts, {employees: 2});
  const imported = await store.list("team-2");
  assert.deepEqual(imported.map((employee) => employee.name), ["Buchhaltung", "Rezeption"]);
  assert.deepEqual(imported.find((employee) => employee.name === "Rezeption")?.skills, ["pdf", "mails"]);
  assert.equal(imported.find((employee) => employee.name === "Rezeption")?.constraint, "Sei freundlich.");
});

test("the manifest counts the exported employees", async (t) => {
  const source = await runtimeTestDatabase(t);
  await new SqliteEmployeeStore(source).create("team-1", {name: "Eins", constraint: "", skills: []});

  const manifest = await new FflateTransferArchiveReader(await exported(t, source)).json("manifest.json") as {counts: Record<string, number>};

  assert.deepEqual(manifest.counts, {employees: 1});
});

test("the same id is overwritten, unrelated employees stay", async (t) => {
  const source = await runtimeTestDatabase(t);
  const original = await new SqliteEmployeeStore(source).create("team-1", {name: "Rezeption", constraint: "Neu", skills: ["pdf"]});
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);
  await importInto(database, archivePath);
  await store.update("team-2", original.id, {name: "Rezeption", constraint: "Lokal geändert", skills: []});
  const other = await store.create("team-2", {name: "Anderer", constraint: "", skills: []});

  await importInto(database, archivePath);

  const rezeption = await store.find("team-2", original.id);
  assert.equal(rezeption?.constraint, "Neu");
  assert.deepEqual(rezeption?.skills, ["pdf"]);
  assert.equal((await store.find("team-2", other.id))?.name, "Anderer");
  assert.equal((await store.list("team-2")).length, 2);
});

test("a name that already exists under another id gets a number instead of a duplicate", async (t) => {
  const source = await runtimeTestDatabase(t);
  await new SqliteEmployeeStore(source).create("team-1", {name: "Rezeption", constraint: "Aus dem Export", skills: []});
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);
  await store.create("team-2", {name: "rezeption", constraint: "Bestand", skills: []});
  await store.create("team-2", {name: "Rezeption (2)", constraint: "Auch belegt", skills: []});

  await importInto(database, archivePath);

  const names = (await store.list("team-2")).map((employee) => employee.name);
  assert.deepEqual(names.sort(), ["Rezeption (2)", "Rezeption (3)", "rezeption"]);
  assert.equal((await store.list("team-2")).find((employee) => employee.name === "Rezeption (3)")?.constraint, "Aus dem Export");
});

test("an id that belongs to another team is never overwritten", async (t) => {
  const source = await runtimeTestDatabase(t);
  const original = await new SqliteEmployeeStore(source).create("team-1", {name: "Rezeption", constraint: "Export", skills: []});
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);
  await database.insert(teams).values({id: "team-3", name: "Fremd", owner_uid: "user-3"});
  await new SqliteEmployeeStore(database).create("team-3", {name: "Fremd", constraint: "Gehört team-3", skills: []});
  const foreign = (await new SqliteEmployeeStore(database).list("team-3"))[0];
  const forged = await rebuilt(t, archivePath, [{id: foreign.id, name: "Eingeschleust", constraint: "x", skills: [], createdAt: "2026-01-01", updatedAt: "2026-01-01"}]);

  await importInto(database, forged).catch(() => undefined);

  assert.equal((await new SqliteEmployeeStore(database).find("team-3", foreign.id))?.constraint, "Gehört team-3");
  assert.deepEqual(await store.list("team-2"), []);
  assert.ok(original.id.length > 0);
});

test("invalid employees make the export invalid and nothing is written", async (t) => {
  const source = await runtimeTestDatabase(t);
  await new SqliteEmployeeStore(source).create("team-1", {name: "Eins", constraint: "", skills: []});
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);
  const employee = (name: string, skills: string[] = []) => ({id: "e-1", name, constraint: "", skills, createdAt: "2026-01-01", updatedAt: "2026-01-01"});

  await assert.rejects(importInto(database, await rebuilt(t, archivePath, [employee("  ")])), InvalidTransferArchiveError);
  await assert.rejects(importInto(database, await rebuilt(t, archivePath, [employee("Gut", ["../ausbruch"])])), /ungültig/);
  await assert.rejects(importInto(database, await rebuilt(t, archivePath, "kaputt")), InvalidTransferArchiveError);

  assert.deepEqual(await store.list("team-2"), []);
});

test("an export without employees imports as zero and deletes nothing", async (t) => {
  const source = await runtimeTestDatabase(t);
  const archivePath = await exported(t, source);
  const {database, store} = await target(t);
  await store.create("team-2", {name: "Bleibt", constraint: "", skills: []});

  assert.deepEqual(await importInto(database, archivePath), {employees: 0});
  assert.deepEqual((await store.list("team-2")).map((employee) => employee.name), ["Bleibt"]);
});
