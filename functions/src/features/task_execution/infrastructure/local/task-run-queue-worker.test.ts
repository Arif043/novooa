import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {type SqliteLocalSqlDatabase} from "../../../../shared/local/sqlite-local-sql-database.js";
import {SQLiteTaskRunDispatcher} from "./sqlite-task-run-dispatcher.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";
import {TaskRunQueueWorker} from "./task-run-queue-worker.js";

test("notifies the queue worker after persisting a task run", async () => {
  await withJobStore(async ({jobStore}) => {
    let notifications = 0;
    const dispatcher = new SQLiteTaskRunDispatcher(jobStore, {
      notify: () => { notifications += 1; },
    });

    await dispatcher.dispatchTaskRun(dispatch("run-1"));

    assert.equal(notifications, 1);
  });
});

test("drains a task run that was queued before startup", async () => {
  await withJobStore(async ({jobStore, database}) => {
    const dispatchedRunIds: string[] = [];
    const worker = new TaskRunQueueWorker(jobStore, async (input) => {
      dispatchedRunIds.push(input.runId);
    });
    const dispatcher = new SQLiteTaskRunDispatcher(jobStore, worker);
    await dispatcher.dispatchTaskRun(dispatch("run-1"));

    worker.start();
    await waitFor(() => dispatchedRunIds.length === 1);
    await worker.stop();

    assert.deepEqual(dispatchedRunIds, ["run-1"]);
    assert.deepEqual(await jobStatus(database, "run-1"), {status: "completed"});
  });
});

test("drains a task run enqueued while another run is processed", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await insertRun(database, "run-2");
    const firstRunStarted = deferred();
    const releaseFirstRun = deferred();
    const dispatchedRunIds: string[] = [];
    const worker = new TaskRunQueueWorker(jobStore, async (input) => {
      if (input.runId === "run-1") {
        firstRunStarted.resolve();
        await releaseFirstRun.promise;
      }
      dispatchedRunIds.push(input.runId);
    });
    const dispatcher = new SQLiteTaskRunDispatcher(jobStore, worker);
    worker.start();
    await dispatcher.dispatchTaskRun(dispatch("run-1"));
    await firstRunStarted.promise;
    await dispatcher.dispatchTaskRun(dispatch("run-2"));
    releaseFirstRun.resolve();

    await waitFor(() => dispatchedRunIds.length === 2);
    await worker.stop();

    assert.deepEqual(dispatchedRunIds, ["run-1", "run-2"]);
    assert.deepEqual(await jobStatus(database, "run-2"), {status: "completed"});
  });
});

test("recovers a job dispatched after the previous worker stopped", async () => {
  await withJobStore(async ({jobStore, database}) => {
    const stoppedWorker = new TaskRunQueueWorker(jobStore, async () => undefined);
    const dispatcher = new SQLiteTaskRunDispatcher(jobStore, stoppedWorker);
    stoppedWorker.start();
    await stoppedWorker.stop();
    await dispatcher.dispatchTaskRun(dispatch("run-1"));

    const recoveredRunIds: string[] = [];
    const recoveringWorker = new TaskRunQueueWorker(jobStore, async (input) => {
      recoveredRunIds.push(input.runId);
    });
    recoveringWorker.start();
    await waitFor(() => recoveredRunIds.length === 1);
    await recoveringWorker.stop();

    assert.deepEqual(recoveredRunIds, ["run-1"]);
    assert.deepEqual(await jobStatus(database, "run-1"), {status: "completed"});
  });
});

function dispatch(runId: string) {
  return {teamId: "team-1", runId, mode: "start" as const};
}

function deferred(): {promise: Promise<void>; resolve: () => void} {
  let resolvePromise: () => void = () => undefined;
  const promise = new Promise<void>((resolve) => { resolvePromise = resolve; });
  return {promise, resolve: resolvePromise};
}

async function waitFor(isReady: () => boolean): Promise<void> {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (isReady()) return;
    await new Promise<void>((resolve) => { setTimeout(resolve, 5); });
  }
  assert.fail("Die erwartete Queue-Verarbeitung ist nicht abgeschlossen.");
}

async function jobStatus(database: SqliteLocalSqlDatabase, runId: string) {
  return database.get<{status: string}>(
    "SELECT status FROM task_run_jobs WHERE run_id = ?", [runId],
  );
}

async function withJobStore(
  operation: (input: {jobStore: SQLiteTaskRunJobStore; database: SqliteLocalSqlDatabase}) => Promise<void>,
): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-task-run-worker-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory,
  });
  try {
    await insertRun(database, "run-1");
    await operation({jobStore: new SQLiteTaskRunJobStore(database), database});
  } finally {
    database.close();
    await rm(directory, {force: true, recursive: true});
  }
}

async function insertRun(database: SqliteLocalSqlDatabase, runId: string): Promise<void> {
  if (runId === "run-1") {
    await database.run("INSERT INTO teams(id, name, owner_uid) VALUES (?, ?, ?)", ["team-1", "Team", "user-1"]);
  }
  await database.run(`INSERT INTO task_runs(
    id, team_id, task_id, task_title, status
  ) VALUES (?, ?, ?, ?, ?)`, [runId, "team-1", "task-1", "Aufgabe", "queued"]);
}

const migrationsDirectory = resolve(
  __dirname,
  "../../../../../../local-runtime/migrations",
);
