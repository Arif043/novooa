import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeDatabase} from "../../db/database.js";
import {teamMembers, userProfiles} from "../../db/schema.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {testRuntimeWorkspace, withRuntimeTestDatabase} from "./local-runtime-test-database.js";

const day = 24 * 60 * 60 * 1000;
const owner = testRuntimeWorkspace.userId;

type Fixture = {database: RuntimeDatabase; clock: {now: number}; store: LocalRuntimeSessionStore; expiresAt: () => Promise<string | undefined>};

function withStore(operation: (fixture: Fixture) => Promise<void>, activeTeam: string | null = testRuntimeWorkspace.teamId) {
  return withRuntimeTestDatabase(async (database) => {
    const clock = {now: Date.parse("2026-10-01T00:00:00.000Z")};
    const store = new LocalRuntimeSessionStore(database, () => activeTeam, () => clock.now);
    const expiresAt = async () => (await database.get<{expires_at: string}>(sql`SELECT expires_at FROM runtime_sessions`))?.expires_at;
    await operation({database, clock, store, expiresAt});
  });
}

async function addMember(database: RuntimeDatabase, uid: string): Promise<void> {
  await database.insert(userProfiles).values({uid, login_name: uid, display_name: uid});
  await database.insert(teamMembers).values({team_id: testRuntimeWorkspace.teamId, uid, role: "member"});
}

test("createSession returns a token that names the account and stores only its hash", () => withStore(async ({database, store}) => {
  const token = await store.createSession(owner);
  const row = await database.get<{token_hash: string; uid: string}>(sql`SELECT token_hash, uid FROM runtime_sessions`);

  assert.deepEqual(await store.verifySession(token), {uid: owner, role: "admin"});
  assert.notEqual(row?.token_hash, token);
  assert.equal(row?.uid, owner);
}));

test("verifySession reads the current role of the account", () => withStore(async ({database, store}) => {
  await addMember(database, "mitglied");
  const token = await store.createSession("mitglied");
  assert.deepEqual(await store.verifySession(token), {uid: "mitglied", role: "member"});

  await database.update(teamMembers).set({role: "admin"});

  assert.deepEqual(await store.verifySession(token), {uid: "mitglied", role: "admin"});
}));

test("verifySession rejects unknown tokens and sessions outside the active team", async () => {
  await withStore(async ({store}) => assert.equal(await store.verifySession("never-issued"), null));
  await withStore(async ({store}) => {
    const token = await store.createSession(owner);
    assert.equal(await store.verifySession(token), null);
  }, "anderes-team");
});

test("a session expires after seven days without use", () => withStore(async ({clock, store}) => {
  const token = await store.createSession(owner);
  clock.now += 7 * day + 1;
  assert.equal(await store.verifySession(token), null);
}));

test("using a session extends it by seven days, at most once per hour", () => withStore(async ({clock, store, expiresAt}) => {
  const token = await store.createSession(owner);
  const created = await expiresAt();

  clock.now += 30 * 60 * 1000;
  assert.notEqual(await store.verifySession(token), null);
  assert.equal(await expiresAt(), created, "innerhalb der ersten Stunde wird nicht geschrieben");

  clock.now += 6 * day;
  assert.notEqual(await store.verifySession(token), null);
  assert.equal(await expiresAt(), new Date(clock.now + 7 * day).toISOString());

  clock.now += 6 * day;
  assert.notEqual(await store.verifySession(token), null, "eine genutzte Sitzung überlebt die ursprünglichen sieben Tage");
}));

test("isActive checks a session without extending it", () => withStore(async ({clock, store, expiresAt}) => {
  const token = await store.createSession(owner);
  const created = await expiresAt();
  clock.now += 3 * day;

  assert.equal(await store.isActive(token), true);
  assert.equal(await expiresAt(), created);
}));

test("deleteSession ends only that session", () => withStore(async ({store}) => {
  const ended = await store.createSession(owner);
  const kept = await store.createSession(owner);

  await store.deleteSession(ended);

  assert.equal(await store.verifySession(ended), null);
  assert.notEqual(await store.verifySession(kept), null);
}));

test("deleteOtherSessions ends only the other sessions of the same account", () => withStore(async ({database, store}) => {
  await addMember(database, "kollegin");
  const current = await store.createSession(owner);
  const others = [await store.createSession(owner), await store.createSession(owner)];
  const colleague = await store.createSession("kollegin");

  assert.equal(await store.deleteOtherSessions(current, owner), 2);

  assert.notEqual(await store.verifySession(current), null);
  for (const other of others) assert.equal(await store.verifySession(other), null);
  assert.notEqual(await store.verifySession(colleague), null);
}));

test("deleteSessionsOf ends every session of one account", () => withStore(async ({database, store}) => {
  await addMember(database, "kollegin");
  const ended = [await store.createSession("kollegin"), await store.createSession("kollegin")];
  const kept = await store.createSession(owner);

  await store.deleteSessionsOf("kollegin");

  for (const token of ended) assert.equal(await store.verifySession(token), null);
  assert.notEqual(await store.verifySession(kept), null);
}));

test("creating a session removes expired ones", () => withStore(async ({database, clock, store}) => {
  await store.createSession(owner);
  clock.now += 8 * day;

  await store.createSession(owner);

  const rows = await database.all<{token_hash: string}>(sql`SELECT token_hash FROM runtime_sessions`);
  assert.equal(rows.length, 1);
}));
