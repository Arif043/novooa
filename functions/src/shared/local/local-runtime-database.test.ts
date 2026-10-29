import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import {createClient} from "@libsql/client";
import {sql} from "drizzle-orm";
import {serializedLibsqlClient} from "../../db/serialized-libsql-client.js";
import {openLocalRuntimeDatabase} from "./local-runtime-database.js";

async function temporaryDirectory(t: test.TestContext) {
  const directory = await mkdtemp(path.join(os.tmpdir(), "novooa-database-"));
  t.after(() => rm(directory, {force: true, recursive: true}));
  return directory;
}

async function openFileDatabase(t: test.TestContext) {
  const database = await openLocalRuntimeDatabase({
    databasePath: path.join(await temporaryDirectory(t), "novooa.sqlite"),
    migrationsDirectory: path.resolve(__dirname, "../../../drizzle"),
  });
  t.after(() => database.$client.close());
  await database.run(sql`CREATE TABLE probe (id TEXT PRIMARY KEY)`);
  return database;
}

const pause = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

test("a write next to an open transaction waits for it instead of failing", async (t) => {
  const database = await openFileDatabase(t);

  const transaction = database.transaction(async (tx) => {
    await tx.run(sql`INSERT INTO probe VALUES ('in-transaction')`);
    await pause(30);
  });
  const beside = database.run(sql`INSERT INTO probe VALUES ('daneben')`);
  await Promise.all([transaction, beside]);

  const rows = await database.all<{id: string}>(sql`SELECT id FROM probe ORDER BY id`);
  assert.deepEqual(rows.map((row) => row.id), ["daneben", "in-transaction"]);
});

test("many transactions and plain writes at the same time all succeed", async (t) => {
  const database = await openFileDatabase(t);

  await Promise.all([
    ...Array.from({length: 20}, (_, index) => database.transaction(async (tx) => {
      await tx.all(sql`SELECT id FROM probe`);
      await pause(1);
      await tx.run(sql`INSERT INTO probe VALUES (${`tx-${index}`})`);
    })),
    ...Array.from({length: 40}, (_, index) => database.run(sql`INSERT INTO probe VALUES (${`log-${index}`})`)),
  ]);

  const [count] = await database.all<{count: number}>(sql`SELECT count(*) AS count FROM probe`);
  assert.equal(count?.count, 60);
});

test("using the outer client inside a transaction fails clearly instead of hanging", async (t) => {
  const client = serializedLibsqlClient(
    createClient({url: `file:${path.join(await temporaryDirectory(t), "misuse.sqlite")}`, concurrency: 1}),
    50,
  );
  t.after(() => client.close());
  const transaction = await client.transaction("write");

  await assert.rejects(client.execute("SELECT 1"), /Transaktion über die äußere Datenbank/);
  await transaction.rollback();
  assert.equal((await client.execute("SELECT 1 AS one")).rows[0]?.one, 1, "the queue runs again afterwards");
});
