import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {TaskRunStepScope} from "../../domain/entities/task-run-step-key.js";
import {SQLiteTaskRunStepJournal} from "./sqlite-task-run-step-journal.js";

const scope = TaskRunStepScope.root("team-1", "run-1");

function resultFor(nodeId: string, value: string): NodeExecutionResult {
  return {
    nodeId, primitive: "script", status: "executed",
    outputs: {value: {type: "string", value}}, console: {stdout: "ausgabe\n", stderr: ""},
  };
}

test("finds a recorded step including its console output", async () => {
  await withJournal(async ({journal}) => {
    await journal.record(scope.forNode("a"), resultFor("a", "erster"));

    assert.deepEqual(await journal.find(scope.forNode("a")), resultFor("a", "erster"));
    assert.equal(await journal.find(scope.forNode("b")), null);
  });
});

test("keeps the first result when a step is recorded twice", async () => {
  await withJournal(async ({journal}) => {
    await journal.record(scope.forNode("a"), resultFor("a", "erster"));
    await journal.record(scope.forNode("a"), resultFor("a", "zweiter"));

    assert.deepEqual((await journal.find(scope.forNode("a")))?.outputs.value, {type: "string", value: "erster"});
  });
});

test("clear removes only the steps of the given run", async () => {
  await withJournal(async ({journal, database}) => {
    await insertRun(database, "run-2");
    const otherRun = TaskRunStepScope.root("team-1", "run-2");
    await journal.record(scope.forNode("a"), resultFor("a", "eins"));
    await journal.record(otherRun.forNode("a"), resultFor("a", "zwei"));

    await journal.clear("team-1", "run-1");

    assert.equal(await journal.find(scope.forNode("a")), null);
    assert.notEqual(await journal.find(otherRun.forNode("a")), null);
  });
});

test("deleting a run deletes its steps", async () => {
  await withJournal(async ({journal, database}) => {
    await journal.record(scope.forNode("a"), resultFor("a", "eins"));

    await database.run(sql`DELETE FROM task_runs WHERE id = ${"run-1"}`);

    assert.equal(await journal.find(scope.forNode("a")), null);
  });
});

async function withJournal(
  operation: (input: {journal: SQLiteTaskRunStepJournal; database: RuntimeDatabase}) => Promise<void>,
): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-task-run-steps-"));
  const database = await openLocalRuntimeDatabase({databasePath: join(directory, "novooa.sqlite"), migrationsDirectory});
  try {
    await database.run(sql`INSERT INTO teams(id, name, owner_uid) VALUES (${"team-1"}, ${"Team"}, ${"user-1"})`);
    await insertRun(database, "run-1");
    await operation({journal: new SQLiteTaskRunStepJournal(database), database});
  } finally {
    database.$client.close();
    await rm(directory, {force: true, recursive: true});
  }
}

async function insertRun(database: RuntimeDatabase, runId: string): Promise<void> {
  await database.run(sql`INSERT INTO task_runs(id, team_id, task_id, task_title, status)
    VALUES (${runId}, ${"team-1"}, ${"task-1"}, ${"Aufgabe"}, ${"running"})`);
}

const migrationsDirectory = resolve(__dirname, "../../../../../drizzle");
