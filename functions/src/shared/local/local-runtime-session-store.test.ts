import assert from "node:assert/strict";
import test from "node:test";
import {SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

test("createSession returns a verifiable token and stores only its hash", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeSessionStore(database);

  const token = await store.createSession();
  const row = await database.get<{token_hash: string}>(
    "SELECT token_hash FROM runtime_sessions",
  );

  assert.equal(await store.verifySession(token), true);
  assert.notEqual(row?.token_hash, token);
  database.close();
});

test("verifySession rejects an unknown token", async () => {
  const store = await storeWithSchema();
  assert.equal(await store.verifySession("never-issued"), false);
});

test("verifySession rejects an expired session", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeSessionStore(database);
  const token = await store.createSession();
  await database.run(
    "UPDATE runtime_sessions SET expires_at = ?",
    ["2000-01-01T00:00:00.000Z"],
  );

  assert.equal(await store.verifySession(token), false);
  database.close();
});

async function storeWithSchema(): Promise<LocalRuntimeSessionStore> {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await createSchema(database);
  return new LocalRuntimeSessionStore(database);
}

async function createSchema(database: SqliteLocalSqlDatabase): Promise<void> {
  await database.run(`
    CREATE TABLE runtime_sessions (
      token_hash TEXT PRIMARY KEY,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TEXT NOT NULL
    )
  `);
}
