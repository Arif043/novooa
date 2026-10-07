import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {connectRuntimeDatabase, RuntimeDatabase} from "../../db/database.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

test("createSession returns a verifiable token and stores only its hash", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeSessionStore(database);

  const token = await store.createSession();
  const row = await database.get <{token_hash: string}>(sql`SELECT token_hash FROM runtime_sessions`);

  assert.equal(await store.verifySession(token), true);
  assert.notEqual(row?.token_hash, token);
  database.$client.close();
});

test("verifySession rejects an unknown token", async () => {
  const store = await storeWithSchema();
  assert.equal(await store.verifySession("never-issued"), false);
});

test("verifySession rejects an expired session", async () => {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  const store = new LocalRuntimeSessionStore(database);
  const token = await store.createSession();
  await database.run(sql`UPDATE runtime_sessions SET expires_at = ${"2000-01-01T00:00:00.000Z"}`);

  assert.equal(await store.verifySession(token), false);
  database.$client.close();
});

const day = 24 * 60 * 60 * 1000;

async function clockedStore() {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  const clock = {now: Date.parse("2026-10-01T00:00:00.000Z")};
  const store = new LocalRuntimeSessionStore(database, () => clock.now);
  const expiresAt = async () => (await database.get<{expires_at: string}>(sql`SELECT expires_at FROM runtime_sessions`))?.expires_at;
  return {database, clock, store, expiresAt};
}

test("a session expires after seven days without use", async () => {
  const {database, clock, store} = await clockedStore();
  const token = await store.createSession();

  clock.now += 7 * day + 1;

  assert.equal(await store.verifySession(token), false);
  database.$client.close();
});

test("using a session extends it by seven days, at most once per hour", async () => {
  const {database, clock, store, expiresAt} = await clockedStore();
  const token = await store.createSession();
  const created = await expiresAt();

  clock.now += 30 * 60 * 1000;
  assert.equal(await store.verifySession(token), true);
  assert.equal(await expiresAt(), created, "innerhalb der ersten Stunde wird nicht geschrieben");

  clock.now += 6 * day;
  assert.equal(await store.verifySession(token), true);
  assert.equal(await expiresAt(), new Date(clock.now + 7 * day).toISOString());

  clock.now += 6 * day;
  assert.equal(await store.verifySession(token), true, "eine genutzte Sitzung überlebt die ursprünglichen sieben Tage");
  database.$client.close();
});

test("isActive checks a session without extending it", async () => {
  const {database, clock, store, expiresAt} = await clockedStore();
  const token = await store.createSession();
  const created = await expiresAt();

  clock.now += 3 * day;

  assert.equal(await store.isActive(token), true);
  assert.equal(await expiresAt(), created);
  database.$client.close();
});

test("deleteSession ends only that session", async () => {
  const {database, store} = await clockedStore();
  const ended = await store.createSession();
  const kept = await store.createSession();

  await store.deleteSession(ended);

  assert.equal(await store.verifySession(ended), false);
  assert.equal(await store.verifySession(kept), true);
  database.$client.close();
});

test("deleteOtherSessions keeps the current session and counts the others", async () => {
  const {database, store} = await clockedStore();
  const current = await store.createSession();
  const others = [await store.createSession(), await store.createSession()];

  assert.equal(await store.deleteOtherSessions(current), 2);

  assert.equal(await store.verifySession(current), true);
  for (const other of others) assert.equal(await store.verifySession(other), false);
  database.$client.close();
});

test("creating a session removes expired ones", async () => {
  const {database, clock, store} = await clockedStore();
  await store.createSession();
  clock.now += 8 * day;

  await store.createSession();

  const rows = await database.all<{token_hash: string}>(sql`SELECT token_hash FROM runtime_sessions`);
  assert.equal(rows.length, 1);
  database.$client.close();
});

async function storeWithSchema(): Promise<LocalRuntimeSessionStore> {
  const database = connectRuntimeDatabase(":memory:");
  await createSchema(database);
  return new LocalRuntimeSessionStore(database);
}

async function createSchema(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`
    CREATE TABLE runtime_sessions (
      token_hash TEXT PRIMARY KEY,
      created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
      expires_at TEXT NOT NULL
    )
  `);
}
