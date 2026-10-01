import {eq} from "drizzle-orm";
import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../db/runtime-database-test-support.js";
import {tasks, teams} from "../../db/schema.js";

test("native Drizzle transactions roll back all writes on failure", async (t) => {
  const database = await runtimeTestDatabase(t);
  await assert.rejects(database.transaction(async (tx) => {
    await tx.insert(teams).values({id: "rollback", name: "Test", owner_uid: "user-1"});
    await tx.insert(tasks).values({id: "task", team_id: "rollback", title: "Test", graph_json: "{}", created_by_uid: "user-1"});
    throw new Error("rollback");
  }), /rollback/);
  assert.equal(await database.select().from(teams).where(eq(teams.id, "rollback")).get(), undefined);
  assert.equal(await database.select().from(tasks).where(eq(tasks.id, "task")).get(), undefined);
});

test("native Drizzle nested transactions use savepoints", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.transaction(async (tx) => {
    await tx.insert(teams).values({id: "outer", name: "Outer", owner_uid: "user-1"});
    await assert.rejects(tx.transaction(async (nested) => {
      await nested.insert(teams).values({id: "inner", name: "Inner", owner_uid: "user-1"});
      throw new Error("savepoint");
    }), /savepoint/);
  });
  assert.ok(await database.select().from(teams).where(eq(teams.id, "outer")).get());
  assert.equal(await database.select().from(teams).where(eq(teams.id, "inner")).get(), undefined);
});

test("runtime migration enables foreign keys and database constraints", async (t) => {
  const database = await runtimeTestDatabase(t);
  await assert.rejects(database.insert(tasks).values({id: "bad", team_id: "missing", title: "Test", graph_json: "{}", created_by_uid: "user-1"}));
  await database.delete(teams).where(eq(teams.id, "team-1"));
  assert.deepEqual(await database.select().from(teams), []);
});
