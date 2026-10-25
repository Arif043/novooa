import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {cp, mkdtemp, readFile, rm, writeFile} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";

const migrationsDirectory = resolve(__dirname, "../../../../../drizzle");

/** Kopie der Migrationen bis einschließlich `lastIndex`. */
async function migrationsUpTo(directory: string, lastIndex: number): Promise<string> {
  const target = join(directory, `drizzle-${lastIndex}`);
  await cp(migrationsDirectory, target, {recursive: true});
  const journalPath = join(target, "meta", "_journal.json");
  const journal = JSON.parse(await readFile(journalPath, "utf8")) as {entries: {idx: number}[]};
  journal.entries = journal.entries.filter((entry) => entry.idx <= lastIndex);
  await writeFile(journalPath, JSON.stringify(journal));
  return target;
}

test("0025 drops the shared password and all sessions and turns owners into admins", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-0025-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  const databasePath = join(directory, "novooa.sqlite");
  const before = await openLocalRuntimeDatabase({databasePath, migrationsDirectory: await migrationsUpTo(directory, 24)});
  await before.run(sql`INSERT INTO user_profiles (uid, display_name) VALUES ('license-1', 'Lokaler Benutzer')`);
  await before.run(sql`INSERT INTO teams (id, name, owner_uid) VALUES ('team-1', 'Team', 'license-1')`);
  await before.run(sql`INSERT INTO team_members (team_id, uid, role) VALUES ('team-1', 'license-1', 'owner')`);
  await before.run(sql`INSERT INTO runtime_access_credential (id, password_hash, salt) VALUES (1, 'hash', 'salt')`);
  await before.run(sql`INSERT INTO runtime_sessions (token_hash, expires_at) VALUES ('alt', '2099-01-01')`);
  before.$client.close();

  const after = await openLocalRuntimeDatabase({databasePath, migrationsDirectory: await migrationsUpTo(directory, 25)});
  t.after(() => after.$client.close());

  assert.deepEqual(await after.all(sql`SELECT role FROM team_members`), [{role: "admin"}]);
  assert.deepEqual(await after.all(sql`SELECT * FROM runtime_sessions`), []);
  assert.deepEqual(await after.all(sql`SELECT login_name FROM user_profiles`), [{login_name: null}]);
  assert.deepEqual(await after.all(sql`SELECT name FROM sqlite_master WHERE name = 'runtime_access_credential'`), []);
  assert.deepEqual(await after.all(sql`SELECT * FROM runtime_password_credentials`), [], "die Runtime verlangt eine neue Einrichtung");
});

test("0026 replaces plain password hashes and ends every session", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-0026-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  const databasePath = join(directory, "novooa.sqlite");
  const before = await openLocalRuntimeDatabase({databasePath, migrationsDirectory: await migrationsUpTo(directory, 25)});
  await before.run(sql`INSERT INTO user_profiles (uid, display_name, login_name) VALUES ('license-1', 'Anna', 'anna')`);
  await before.run(sql`INSERT INTO runtime_password_credentials (uid, password_hash, salt) VALUES ('license-1', 'hash', 'salt')`);
  await before.run(sql`INSERT INTO runtime_sessions (token_hash, uid, expires_at) VALUES ('alt', 'license-1', '2099-01-01')`);
  before.$client.close();

  const after = await openLocalRuntimeDatabase({databasePath, migrationsDirectory});
  t.after(() => after.$client.close());

  assert.deepEqual(await after.all(sql`SELECT * FROM runtime_password_credentials`), [], "die Runtime verlangt eine neue Einrichtung");
  assert.deepEqual(await after.all(sql`SELECT * FROM runtime_sessions`), []);
  const columns = await after.all<{name: string}>(sql`SELECT name FROM pragma_table_info('runtime_password_credentials')`);
  assert.deepEqual(columns.map((column) => column.name), ["uid", "encrypted_hash", "salt", "updated_at"]);
  assert.deepEqual(await after.all(sql`SELECT login_name FROM user_profiles`), [{login_name: "anna"}]);
});

test("0027 keeps existing sessions and gives each a public id", async (t) => {
  const directory = await mkdtemp(join(tmpdir(), "novooa-0027-"));
  t.after(() => rm(directory, {recursive: true, force: true}));
  const databasePath = join(directory, "novooa.sqlite");
  const before = await openLocalRuntimeDatabase({databasePath, migrationsDirectory: await migrationsUpTo(directory, 26)});
  await before.run(sql`INSERT INTO user_profiles (uid, display_name, login_name) VALUES ('license-1', 'Anna', 'anna')`);
  await before.run(sql`INSERT INTO runtime_sessions (token_hash, uid, expires_at) VALUES ('alt', 'license-1', '2099-01-08T00:00:00.000Z')`);
  before.$client.close();

  const after = await openLocalRuntimeDatabase({databasePath, migrationsDirectory});
  t.after(() => after.$client.close());

  const [session] = await after.all<Record<string, unknown>>(sql`SELECT * FROM runtime_sessions`);
  assert.equal(session.token_hash, "alt");
  assert.match(String(session.id), /^[0-9a-f]{32}$/);
  assert.equal(session.device_os, "unknown");
  assert.equal(session.device_app, "");
  assert.equal(session.last_used_at, "2099-01-01T00:00:00.000Z");
});
