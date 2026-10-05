import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";
import {TaskRunQueueWorker} from "./task-run-queue-worker.js";

test("does not retry a task run whose dispatch throws", async () => {
  await withJobStore(async ({jobStore, database}) => {
    let dispatches = 0;
    const worker = new TaskRunQueueWorker(jobStore, async () => {
      dispatches += 1;
      throw new Error("Baustein fehlgeschlagen");
    });
    await jobStore.enqueue(startDispatch);

    worker.start();
    await waitFor(async () => (await jobStatus(database)) === "failed");
    await worker.stop();

    assert.equal(dispatches, 1);
    assert.equal(await jobStore.claimNext(), null);
  });
});

test("retries a task run whose previous worker crashed", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(startDispatch);
    await jobStore.claimNext();
    await expireLeases(database);
    const recoveredRunIds: string[] = [];
    const worker = new TaskRunQueueWorker(jobStore, async (input) => {
      recoveredRunIds.push(input.runId);
    });

    worker.start();
    await waitFor(async () => (await jobStatus(database)) === "completed");
    await worker.stop();

    assert.deepEqual(recoveredRunIds, ["run-1"]);
    const row = await database.get<{attempts: number}>(sql`SELECT attempts FROM task_run_jobs`);
    assert.equal(row.attempts, 2);
  });
});

test("abandons a task run that crashed on every attempt", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(startDispatch);
    await jobStore.claimNext();
    await expireLeases(database);
    const abandonedRunIds: string[] = [];
    let dispatches = 0;
    const worker = new TaskRunQueueWorker(jobStore, async () => { dispatches += 1; }, {
      maximumAttempts: 1,
      onAbandoned: async (job) => { abandonedRunIds.push(job.runId); },
    });

    worker.start();
    await waitFor(async () => abandonedRunIds.length === 1);
    await worker.stop();

    assert.deepEqual(abandonedRunIds, ["run-1"]);
    assert.equal(dispatches, 0);
    assert.equal(await jobStatus(database), "failed");
  });
});

const startDispatch = {teamId: "team-1", runId: "run-1", mode: "start" as const};

async function expireLeases(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`UPDATE task_run_jobs SET lease_expires_at = datetime('now', '-1 seconds')`);
}

async function jobStatus(database: RuntimeDatabase): Promise<string | undefined> {
  const row = await database.get<{status: string} | undefined>(sql`SELECT status FROM task_run_jobs`);
  return row?.status;
}

async function waitFor(isReady: () => Promise<boolean>): Promise<void> {
  for (let attempt = 0; attempt < 100; attempt += 1) {
    if (await isReady()) return;
    await new Promise<void>((resolve) => { setTimeout(resolve, 5); });
  }
  assert.fail("Die erwartete Queue-Verarbeitung ist nicht abgeschlossen.");
}

async function withJobStore(
  operation: (input: {jobStore: SQLiteTaskRunJobStore; database: RuntimeDatabase}) => Promise<void>,
): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-task-run-worker-failure-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory,
  });
  try {
    await database.run(sql`INSERT INTO teams(id, name, owner_uid) VALUES (${"team-1"}, ${"Team"}, ${"user-1"})`);
    await database.run(sql`INSERT INTO task_runs(id, team_id, task_id, task_title, status)
      VALUES (${"run-1"}, ${"team-1"}, ${"task-1"}, ${"Aufgabe"}, ${"running"})`);
    await operation({jobStore: new SQLiteTaskRunJobStore(database), database});
  } finally {
    database.$client.close();
    await rm(directory, {force: true, recursive: true});
  }
}

const migrationsDirectory = resolve(__dirname, "../../../../../drizzle");
