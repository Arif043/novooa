import assert from "node:assert/strict";
import {mkdtemp, rm} from "node:fs/promises";
import {tmpdir} from "node:os";
import {join, resolve} from "node:path";
import test from "node:test";
import {openLocalRuntimeDatabase} from "../../../../shared/local/local-runtime-database.js";
import {type SqliteLocalSqlDatabase} from "../../../../shared/local/sqlite-local-sql-database.js";
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

test("marks a failed dispatch as terminal after the final attempt", async () => {
  await withJobStore(async ({jobStore, database}) => {
    await jobStore.enqueue(dispatch("start"));
    const job = await jobStore.claimNext();
    if (job === null) throw new Error("Der erwartete Job fehlt.");

    await jobStore.retryOrFail(job, 1);

    const row = await database.get<{status: string; attempts: number}>(
      "SELECT status, attempts FROM task_run_jobs",
    );
    assert.deepEqual(row, {status: "failed", attempts: 1});
  });
});

function dispatch(mode: "start" | "resume") {
  return {teamId: "team-1", runId: "run-1", mode};
}

async function withJobStore(
  operation: (input: {jobStore: SQLiteTaskRunJobStore; database: SqliteLocalSqlDatabase}) => Promise<void>,
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
    database.close();
    await rm(directory, {force: true, recursive: true});
  }
}

async function insertRun(database: SqliteLocalSqlDatabase): Promise<void> {
  await database.run("INSERT INTO teams(id, name, owner_uid) VALUES (?, ?, ?)", ["team-1", "Team", "user-1"]);
  await database.run(`INSERT INTO task_runs(
    id, team_id, task_id, task_title, status
  ) VALUES (?, ?, ?, ?, ?)`, ["run-1", "team-1", "task-1", "Aufgabe", "queued"]);
}

const migrationsDirectory = resolve(
  __dirname,
  "../../../../../../local-runtime/migrations",
);
