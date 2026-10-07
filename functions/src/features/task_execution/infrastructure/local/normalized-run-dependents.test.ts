import {eq, sql} from "drizzle-orm";
import assert from "node:assert/strict";
import test, {type TestContext} from "node:test";
import {runtimeTestDatabase} from "../../../../db/runtime-database-test-support.js";
import {taskRunJobs, taskRunSteps, taskRuns, teams} from "../../../../db/schema.js";
import {TaskRunStepScope} from "../../domain/entities/task-run-step-key.js";
import {type NodeExecutionResult} from "../../domain/entities/task.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";
import {SQLiteTaskRunStepJournal} from "./sqlite-task-run-step-journal.js";

const dispatch = {teamId: "team-1", runId: "run-1", mode: "start" as const};
const step = TaskRunStepScope.root("team-1", "run-1").forNode("node-1");
const execution: NodeExecutionResult = {nodeId: "node-1", primitive: "script", status: "executed", outputs: {}};

async function fixture(t: TestContext) {
  const database = await runtimeTestDatabase(t);
  await database.insert(teams).values({id: "team-2", name: "Anderes Team", owner_uid: "user-2"});
  await database.insert(taskRuns).values({id: "run-1", team_id: "team-1", task_id: "task-1",
    task_title: "Historischer Titel", status: "queued"});
  return {database, jobs: new SQLiteTaskRunJobStore(database), journal: new SQLiteTaskRunStepJournal(database)};
}

test("a foreign or missing run cannot enqueue or reset a job", async (t) => {
  const {database, jobs} = await fixture(t);
  await jobs.enqueue(dispatch);
  const job = await jobs.claimNext();
  assert.ok(job);
  await assert.rejects(jobs.enqueue({...dispatch, teamId: "team-2"}));
  await assert.rejects(jobs.enqueue({...dispatch, runId: "missing"}));
  const [row] = await database.select().from(taskRunJobs);
  assert.equal(row.status, "leased");
  assert.equal(row.attempts, 1);
});

test("completion and failure cannot mutate a job through another team", async (t) => {
  const {database, jobs} = await fixture(t);
  await jobs.enqueue(dispatch);
  const job = await jobs.claimNext();
  assert.ok(job);
  await jobs.complete({...job, teamId: "team-2"});
  await jobs.fail({...job, runId: "missing"});
  assert.equal((await database.select().from(taskRunJobs))[0].status, "leased");
  await jobs.complete(job);
  assert.equal((await database.select().from(taskRunJobs))[0].status, "completed");
});

test("step writes, reads and clearing respect the run's team", async (t) => {
  const {database, journal} = await fixture(t);
  const foreignStep = TaskRunStepScope.root("team-2", "run-1").forNode("node-1");
  await journal.record(step, execution);
  await assert.rejects(journal.record(foreignStep, execution));
  await assert.rejects(journal.record(TaskRunStepScope.root("team-1", "missing").forNode("node-1"), execution));
  assert.equal(await journal.find(foreignStep), null);
  await journal.clear("team-2", "run-1");
  assert.deepEqual(await journal.find(step), execution);
  assert.equal((await database.select().from(taskRunSteps)).length, 1);
});

test("run deletion cascades jobs and steps; unrelated team deletion preserves them", async (t) => {
  const {database, jobs, journal} = await fixture(t);
  await jobs.enqueue(dispatch);
  await journal.record(step, execution);
  await database.delete(teams).where(eq(teams.id, "team-2"));
  assert.equal((await database.select().from(taskRunJobs)).length, 1);
  assert.equal((await database.select().from(taskRunSteps)).length, 1);
  await database.delete(taskRuns).where(eq(taskRuns.id, "run-1"));
  assert.deepEqual(await database.select().from(taskRunJobs), []);
  assert.deepEqual(await database.select().from(taskRunSteps), []);
});

test("run dependents require a parent and have no duplicate team column", async (t) => {
  const {database} = await fixture(t);
  await assert.rejects(database.insert(taskRunJobs).values({id: "job-1", run_id: "missing", mode: "start", status: "queued"}));
  await assert.rejects(database.insert(taskRunSteps).values({run_id: "missing", step_path: "node-1", result_json: "{}"}));
  for (const table of [taskRunJobs, taskRunSteps]) {
    const columns = await database.all<{name: string}>(sql`PRAGMA table_info(${table})`);
    assert.ok(!columns.some((column) => column.name === "team_id"));
  }
});
