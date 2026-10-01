import assert from "node:assert/strict";
import test from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {teams} from "../../../../db/schema.js";
import {SQLiteTaskDefinitionStore} from "./sqlite-task-definition-store.js";

test("task upserts never overwrite a task owned by another team", async (t) => {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Other", owner_uid: "user-2"});
  const store = new SQLiteTaskDefinitionStore(database);
  const definition = {id: "shared-id", title: "Original", objective: "", nodes: [], edges: []};
  await store.save("team-1", "user-1", definition, "selected-1");
  await store.save("team-2", "user-2", {...definition, title: "Wrong team"}, "selected-2");
  assert.equal((await store.list("team-1"))[0].title, "Original");
  assert.equal(await store.selectedNodeId("team-1", "shared-id"), "selected-1");
  assert.deepEqual(await store.list("team-2"), []);
  await store.save("team-1", "user-1", {...definition, title: "Updated"}, "updated-node");
  assert.equal((await store.list("team-1"))[0].title, "Updated");
  assert.equal(await store.selectedNodeId("team-1", "shared-id"), "updated-node");
});
