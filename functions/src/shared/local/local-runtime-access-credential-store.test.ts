import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../db/database.js";
import {
  LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";

test("hasCredential is false before a password is set", async () => {
  const store = await storeWithSchema();
  assert.equal(await store.hasCredential(), false);
});

test("stores a scrypt hash, never the plaintext password", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeAccessCredentialStore(database);

  await store.setPassword("correct-horse-battery-staple");
  const row = await database.get <{password_hash: string}>(sql`SELECT password_hash FROM runtime_access_credential WHERE id = 1`);

  assert.equal(await store.hasCredential(), true);
  assert.notEqual(row?.password_hash, "correct-horse-battery-staple");
  database.$client.close();
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
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  return new LocalRuntimeAccessCredentialStore(database);
}

async function createSchema(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`
    CREATE TABLE runtime_access_credential (
      id INTEGER PRIMARY KEY CHECK (id = 1),
      password_hash TEXT NOT NULL,
      salt TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
    )
  `);
}

test("hashing does not block the event loop and concurrent checks stay correct", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeAccessCredentialStore(database);
  await store.setPassword("correct-horse-battery-staple");
  let eventLoopTicked = false;
  const checks = Promise.all([
    store.verifyPassword("correct-horse-battery-staple"),
    store.verifyPassword("wrong-password"),
  ]).then((results) => ({results, ticked: eventLoopTicked}));
  setImmediate(() => { eventLoopTicked = true; });

  const {results, ticked} = await checks;

  assert.deepEqual(results, [true, false]);
  assert.equal(ticked, true, "der Event-Loop lief weiter, während gehasht wurde");
  database.$client.close();
});
