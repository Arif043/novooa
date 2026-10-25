import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeDatabase} from "../../db/database.js";
import {teamMembers, userProfiles} from "../../db/schema.js";
import {SessionDevice} from "../../features/runtime_users/domain/entities/session-device.js";
import {LocalRuntimeSessionStore} from "./local-runtime-session-store.js";
import {testRuntimeWorkspace, withRuntimeTestDatabase} from "./local-runtime-test-database.js";

const hour = 60 * 60 * 1000;
const owner = testRuntimeWorkspace.userId;
const chromeOnMac = SessionDevice.from({app: "novooa", os: "macos", browser: "Chrome"});

type Fixture = {database: RuntimeDatabase; clock: {now: number}; store: LocalRuntimeSessionStore};

function withStore(operation: (fixture: Fixture) => Promise<void>) {
  return withRuntimeTestDatabase(async (database) => {
    const clock = {now: Date.parse("2026-10-01T00:00:00.000Z")};
    const store = new LocalRuntimeSessionStore(database, () => testRuntimeWorkspace.teamId, () => clock.now);
    await operation({database, clock, store});
  });
}

async function addMember(database: RuntimeDatabase, uid: string): Promise<void> {
  await database.insert(userProfiles).values({uid, login_name: uid, display_name: uid});
  await database.insert(teamMembers).values({team_id: testRuntimeWorkspace.teamId, uid, role: "member"});
}

test("listSessionsOf shows the own sessions with device, marks the current one and puts the last used first", () =>
  withStore(async ({database, clock, store}) => {
    await addMember(database, "kollegin");
    const current = await store.createSession(owner, chromeOnMac);
    clock.now += 2 * hour;
    await store.createSession(owner);
    await store.createSession("kollegin");

    const sessions = await store.listSessionsOf(owner, current);

    assert.deepEqual(sessions.map((session) => [session.current, session.device.os, session.device.browser]),
      [[false, "unknown", null], [true, "macos", "Chrome"]]);
    assert.equal(sessions[1].createdAt, "2026-10-01T00:00:00.000Z");
    assert.match(sessions[0].id, /^[0-9a-f]{32}$/);
  }));

test("using a session updates when it was last used, at most once per hour", () => withStore(async ({clock, store}) => {
  const token = await store.createSession(owner);
  clock.now += 3 * hour;

  await store.verifySession(token);

  const [session] = await store.listSessionsOf(owner, token);
  assert.equal(session.lastUsedAt, "2026-10-01T03:00:00.000Z");
}));

test("deleteOwnSession ends one other session of the same account only", () => withStore(async ({database, store}) => {
  await addMember(database, "kollegin");
  const current = await store.createSession(owner);
  const other = await store.createSession(owner);
  const colleague = await store.createSession("kollegin");
  const ids = async (uid: string, token: string) => (await store.listSessionsOf(uid, token)).map((session) => session);
  const otherId = (await ids(owner, current)).find((session) => !session.current)?.id ?? "";
  const currentId = (await ids(owner, current)).find((session) => session.current)?.id ?? "";
  const colleagueId = (await ids("kollegin", colleague))[0].id;

  assert.equal(await store.deleteOwnSession(owner, currentId, current), false, "die eigene Sitzung endet über logout");
  assert.equal(await store.deleteOwnSession(owner, colleagueId, current), false);
  assert.equal(await store.deleteOwnSession(owner, otherId, current), true);

  assert.equal(await store.verifySession(other), null);
  assert.notEqual(await store.verifySession(current), null);
  assert.notEqual(await store.verifySession(colleague), null);
}));
