import {sql} from "drizzle-orm";
import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {type RuntimeDatabase} from "../../../../db/database.js";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {SQLiteTaskRunJobStore} from "./sqlite-task-run-job-store.js";

test("persists and leases a dispatched task run", async () => {
  await withJobStore(async ({jobStore}) => {
    await jobStore.enqueue(dispatch("start"));

    const job = await jobStore.claimNext();

    assert.equal(job?.teamId, "team-1");
    assert.equal(job?.runId, "run-1");
    assert.equal(job?.mode, "start");
    assert.equal(job?.attempt, 1);
    assert.match(job?.jobId ?? "", /^.+$/);
  });
});

test("resets a completed job when an approval resumes its run", async () => {
  await withJobStore(async ({jobStore}) => {
    await jobStore.enqueue(dispatch("start"));
    const firstJob = await jobStore.claimNext();
    if (firstJob === null) throw new Error("Der erwartete Job fehlt.");
    await jobStore.complete(firstJob);

    await jobStore.enqueue(dispatch("resume"));
    const resumedJob = await jobStore.claimNext();

    assert.equal(resumedJob?.mode, "resume");
    assert.equal(resumedJob?.attempt, 1);
  });
});

test("marks a failed dispatch as terminal on the first attempt", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    const job = await jobStore.claimNext();
    if (job === null) throw new Error("Der erwartete Job fehlt.");

    await jobStore.fail(job);

    assert.deepEqual(await jobRow(database), {status: "failed", attempts: 1});
    assert.equal(await jobStore.claimNext(), null);
  });
});

test("reclaims a job whose lease expired after a crash", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    await jobStore.claimNext();
    await expireLeases(database);

    const reclaimedJob = await jobStore.claimNext();

    assert.equal(reclaimedJob?.runId, "run-1");
    assert.equal(reclaimedJob?.attempt, 2);
  });
});

test("abandons a crashed job once its attempts are exhausted", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    await jobStore.claimNext();
    await expireLeases(database);

    assert.deepEqual(await jobStore.abandonExhaustedLeases(2), []);
    await jobStore.claimNext();
    await expireLeases(database);
    const abandonedJobs = await jobStore.abandonExhaustedLeases(2);

    assert.deepEqual(abandonedJobs.map((job) => job.runId), ["run-1"]);
    assert.deepEqual(await jobRow(database), {status: "failed", attempts: 2});
    assert.equal(await jobStore.claimNext(), null);
  });
});

test("keeps an active lease when abandoning exhausted jobs", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    await jobStore.claimNext();

    assert.deepEqual(await jobStore.abandonExhaustedLeases(1), []);
    assert.deepEqual(await jobRow(database), {status: "leased", attempts: 1});
  });
});

async function jobRow(database: RuntimeDatabase) {
  return database.get <{status: string; attempts: number}>(sql`SELECT status, attempts FROM task_run_jobs`);
}

async function expireLeases(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`UPDATE task_run_jobs SET lease_expires_at = datetime('now', '-1 seconds')`);
}

function dispatch(mode: "start" | "resume") {
  return {teamId: "team-1", runId: "run-1", mode};
}

test("concurrent workers cannot lease the same job twice", async () => {
  await withJobStore(async ({jobStore}) => {
    await jobStore.enqueue(dispatch("start"));
    const claims = await Promise.all([jobStore.claimNext(), jobStore.claimNext()]);
    assert.equal(claims.filter((job) => job !== null).length, 1);
    assert.equal(claims.find((job) => job !== null)?.attempt, 1);
  });
});

test("calculates delay from the earliest queued or leased job", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    await database.run(sql`UPDATE task_run_jobs SET available_at = datetime('now', '+30 seconds')`);
    const delay = await jobStore.nextClaimableDelayMs();
    assert.ok(delay !== null && delay >= 29_000 && delay <= 30_000);
    await database.run(sql`INSERT INTO task_runs(id, team_id, task_id, task_title, status)
      VALUES ('run-2', 'team-1', 'task-1', 'Aufgabe', 'queued')`);
    await jobStore.enqueue({teamId: "team-1", runId: "run-2", mode: "start"});
    assert.equal(await jobStore.nextClaimableDelayMs(), 0);
  });
});

async function withJobStore(
  operation: (input: {jobStore: SQLiteTaskRunJobStore; database: RuntimeDatabase}) => Promise<void>,
): Promise<void> {
  const directory = await mkdtemp(join(tmpdir(), "novooa-task-run-job-"));
  const database = await openLocalRuntimeDatabase({
    databasePath: join(directory, "novooa.sqlite"),
    migrationsDirectory,
  });
  try {
    await insertRun(database);
    await operation({jobStore: new SQLiteTaskRunJobStore(database), database});
  } finally {
    database.$client.close();
    await rm(directory, {force: true, recursive: true});
  }
}

async function insertRun(database: RuntimeDatabase): Promise<void> {
  await database.run(sql`INSERT INTO teams(id, name, owner_uid) VALUES (${"team-1"}, ${"Team"}, ${"user-1"})`);
  await database.run(sql`INSERT INTO task_runs(
    id, team_id, task_id, task_title, status
  ) VALUES (${"run-1"}, ${"team-1"}, ${"task-1"}, ${"Aufgabe"}, ${"queued"})`);
}

const migrationsDirectory = resolve(
  __dirname,
  "../../../../../drizzle",
);
