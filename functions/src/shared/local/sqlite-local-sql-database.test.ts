import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";
import {SqlMigrationRunner} from "./sql-migration-runner.js";
import {SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";

test("persists parameterized queries in a file database", async () => {
  await withDatabase(async (database) => {
    await database.run("CREATE TABLE notes (id TEXT PRIMARY KEY, title TEXT NOT NULL)");
    await database.run("INSERT INTO notes(id, title) VALUES (?, ?)", ["note-1", "Erste Notiz"]);
    const note = await database.get<{id: string; title: string}>("SELECT id, title FROM notes WHERE id = ?", ["note-1"]);
    assert.deepEqual(note, {id: "note-1", title: "Erste Notiz"});
  });
});

test("rolls back a failed transaction", async () => {
  await withDatabase(async (database) => {
    await database.run("CREATE TABLE entries (id TEXT PRIMARY KEY)");
    await assert.rejects(database.transaction(async () => {
      await database.run("INSERT INTO entries(id) VALUES (?)", ["entry-1"]);
      throw new Error("Fehler beim Speichern");
    }), /Fehler beim Speichern/);
    assert.deepEqual(await database.all("SELECT id FROM entries"), []);
  });
});

test("applies each migration once", async () => {
  await withDatabase(async (database) => {
    const migrationRunner = new SqlMigrationRunner(database);
    const migrations = [{version: "001", statements: ["CREATE TABLE tasks (id TEXT PRIMARY KEY)"]}];
    assert.deepEqual(await migrationRunner.run(migrations), ["001"]);
    assert.deepEqual(await migrationRunner.run(migrations), []);
  });
});

test("initializes all local runtime migrations", async () => {
  await withInitializedRuntimeDatabase(async (database) => {
    const tables = await database.all<{name: string}>(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    );
    assert.equal(tables.some((table) => table.name === "language_models"), true);
    const migrations = await database.all<{version: string}>("SELECT version FROM schema_migrations ORDER BY version");
    assert.deepEqual(migrations.map((migration) => migration.version), expectedMigrationVersions);
  });
});

async function withDatabase(operation: (database: SqliteLocalSqlDatabase) => Promise<void>): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-sqlite-"));
  const database = new SqliteLocalSqlDatabase(join(directory, "novooa.sqlite"));
  try {
    await operation(database);
  } finally {
    database.close();
    await rm(directory, {force: true, recursive: true});
  }
}

async function withInitializedRuntimeDatabase(operation: (database: SqliteLocalSqlDatabase) => Promise<void>): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-runtime-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory: migrationDirectory,
  });
  try {
    await operation(database);
  } finally {
    database.close();
    await rm(directory, {force: true, recursive: true});
  }
}

const expectedMigrationVersions = [
  "001_initial",
  "002_task_run_response_outputs",
  "003_task_run_interaction",
  "004_model_catalog",
  "005_language_models",
  "006_task_run_jobs",
  "007_task_selection",
  "008_file_folders",
];

const migrationDirectory = resolve(__dirname, "../../../../local-runtime/migrations");
