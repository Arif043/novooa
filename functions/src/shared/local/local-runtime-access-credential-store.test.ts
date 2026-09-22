import assert from "node:assert/strict";
import test from "node:test";
import {SqliteLocalSqlDatabase} from "./sqlite-local-sql-database.js";
import {
  LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";

test("hasCredential is false before a password is set", async () => {
  const store = await storeWithSchema();
  assert.equal(await store.hasCredential(), false);
});

test("stores a scrypt hash, never the plaintext password", async () => {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeAccessCredentialStore(database);

  await store.setPassword("correct-horse-battery-staple");
  const row = await database.get<{password_hash: string}>(
    "SELECT password_hash FROM runtime_access_credential WHERE id = 1",
  );

  assert.equal(await store.hasCredential(), true);
  assert.notEqual(row?.password_hash, "correct-horse-battery-staple");
  database.close();
});

test("verifyPassword accepts the correct password and rejects a wrong one", async () => {
  const store = await storeWithSchema();
  await store.setPassword("correct-horse-battery-staple");

  assert.equal(await store.verifyPassword("correct-horse-battery-staple"), true);
  assert.equal(await store.verifyPassword("wrong-password"), false);
});

test("verifyPassword is false when no password has been set yet", async () => {
  const store = await storeWithSchema();
  assert.equal(await store.verifyPassword("anything"), false);
});

test("setPassword throws and does not overwrite an existing password", async () => {
  const store = await storeWithSchema();
  await store.setPassword("first-password");

  await assert.rejects(
    () => store.setPassword("second-password"),
    RuntimeAccessCredentialAlreadySetError,
  );
  assert.equal(await store.verifyPassword("first-password"), true);
  assert.equal(await store.verifyPassword("second-password"), false);
});

async function storeWithSchema(): Promise<LocalRuntimeAccessCredentialStore> {
  const database = new SqliteLocalSqlDatabase(":memory:");
  await createSchema(database);
  return new LocalRuntimeAccessCredentialStore(database);
}

async function createSchema(database: SqliteLocalSqlDatabase): Promise<void> {
  await database.run(`
    CREATE TABLE runtime_access_credential (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
}
