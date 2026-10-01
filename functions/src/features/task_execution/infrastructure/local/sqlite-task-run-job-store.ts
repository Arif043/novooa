import {and, eq, inArray, lte, or, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {
  type RuntimeExecutor,
} from "../../../../db/database.js";
import {taskRunJobs, type TaskRunJobs} from "../../../../db/schema.js";
import {
  type TaskRunDispatch,
} from "../../domain/usecases/task-workflow.js";

type TaskRunJobRow = Pick<TaskRunJobs, "id" | "team_id" | "run_id" | "mode" | "attempts">;

export type LeasedTaskRunJob = TaskRunDispatch & {
  jobId: string;
  attempt: number;
};

export class SQLiteTaskRunJobStore {
  constructor(
    private readonly database: RuntimeExecutor,
    private readonly leaseSeconds = 60,
  ) {}

  async enqueue(input: TaskRunDispatch): Promise<void> {
    await this.database.insert(taskRunJobs).values({id: randomUUID(), team_id: input.teamId, run_id: input.runId, mode: input.mode, status: "queued", attempts: 0, available_at: sql`CURRENT_TIMESTAMP`}).onConflictDoUpdate({target: [taskRunJobs.team_id, taskRunJobs.run_id], set: {mode: input.mode, status: "queued", attempts: 0, available_at: sql`CURRENT_TIMESTAMP`, lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}});
  }

  async claimNext(): Promise<LeasedTaskRunJob | null> {
    const nextJob = this.database.select({id: taskRunJobs.id}).from(taskRunJobs).where(or(
      and(eq(taskRunJobs.status, "queued"), lte(taskRunJobs.available_at, sql`CURRENT_TIMESTAMP`)),
      and(eq(taskRunJobs.status, "leased"), lte(taskRunJobs.lease_expires_at, sql`CURRENT_TIMESTAMP`)),
    )).orderBy(taskRunJobs.available_at, taskRunJobs.created_at).limit(1);
    const [job] = await this.database.update(taskRunJobs).set({status: "leased",
      attempts: sql`${taskRunJobs.attempts} + 1`, updated_at: sql`CURRENT_TIMESTAMP`,
      lease_expires_at: sql`datetime('now', ${`+${this.leaseSeconds} seconds`})`,
    }).where(eq(taskRunJobs.id, nextJob)).returning();
    return job ? leasedJobFrom(job) : null;
  }

  async complete(job: LeasedTaskRunJob): Promise<void> {
    await this.database.update(taskRunJobs).set({status: "completed", lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRunJobs.id, job.jobId), eq(taskRunJobs.status, "leased")));
  }

  async retryOrFail(job: LeasedTaskRunJob, maximumAttempts: number): Promise<void> {
    if (job.attempt >= maximumAttempts) {
      await this.database.update(taskRunJobs).set({status: "failed", lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRunJobs.id, job.jobId), eq(taskRunJobs.status, "leased")));
      return;
    }
    await this.database.update(taskRunJobs).set({status: "queued", available_at: sql`datetime('now', ${`+${backoffSecondsFor(job.attempt)} seconds`})`, lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(eq(taskRunJobs.id, job.jobId), eq(taskRunJobs.status, "leased")));
  }

  async nextClaimableDelayMs(): Promise<number | null> {
    const row = await this.database.select({delay_ms: sql<number | null>`MAX(0,
      (unixepoch(MIN(CASE WHEN ${taskRunJobs.status} = 'queued'
        THEN ${taskRunJobs.available_at} ELSE ${taskRunJobs.lease_expires_at} END)) - unixepoch('now')) * 1000)`})
      .from(taskRunJobs).where(inArray(taskRunJobs.status, ["queued", "leased"])).get();
    return row?.delay_ms ?? null;
  }
}

function leasedJobFrom(row: TaskRunJobRow): LeasedTaskRunJob {
  return {
    jobId: row.id,
    teamId: row.team_id,
    runId: row.run_id,
    mode: row.mode,
    attempt: row.attempts,
  };
}

function backoffSecondsFor(attempt: number): number {
  return Math.min(30 * 2 ** (attempt - 1), 300);
}
