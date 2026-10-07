import {and, eq, gte, inArray, lte, or, sql} from "drizzle-orm";
import {randomUUID} from "node:crypto";
import {
  type RuntimeExecutor,
} from "../../../../db/database.js";
import {taskRunJobs, taskRuns, type TaskRunJobs} from "../../../../db/schema.js";
import {
  type TaskRunDispatch,
} from "../../domain/usecases/task-workflow.js";
import {requireTeamRun, teamRunId} from "./sqlite-team-run.js";

type TaskRunJobRow = Pick<TaskRunJobs, "id" | "run_id" | "mode" | "attempts"> & {team_id: string};

const leasedJobColumns = {
  id: taskRunJobs.id, run_id: taskRunJobs.run_id, mode: taskRunJobs.mode, attempts: taskRunJobs.attempts,
  team_id: sql<string>`(SELECT ${taskRuns.team_id} FROM ${taskRuns} WHERE ${taskRuns.id} = ${taskRunJobs.run_id})`,
};

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
    await this.database.transaction(async (tx) => {
      await requireTeamRun(tx, input.teamId, input.runId);
      await tx.insert(taskRunJobs).values({id: randomUUID(), run_id: input.runId, mode: input.mode,
        status: "queued", attempts: 0, available_at: sql`CURRENT_TIMESTAMP`})
        .onConflictDoUpdate({target: taskRunJobs.run_id, set: {mode: input.mode, status: "queued",
          attempts: 0, available_at: sql`CURRENT_TIMESTAMP`, lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}});
    });
  }

  async claimNext(): Promise<LeasedTaskRunJob | null> {
    const nextJob = this.database.select({id: taskRunJobs.id}).from(taskRunJobs).where(or(
      and(eq(taskRunJobs.status, "queued"), lte(taskRunJobs.available_at, sql`CURRENT_TIMESTAMP`)),
      and(eq(taskRunJobs.status, "leased"), lte(taskRunJobs.lease_expires_at, sql`CURRENT_TIMESTAMP`)),
    )).orderBy(taskRunJobs.available_at, taskRunJobs.created_at).limit(1);
    const [job] = await this.database.update(taskRunJobs).set({status: "leased",
      attempts: sql`${taskRunJobs.attempts} + 1`, updated_at: sql`CURRENT_TIMESTAMP`,
      lease_expires_at: sql`datetime('now', ${`+${this.leaseSeconds} seconds`})`,
    }).where(eq(taskRunJobs.id, nextJob)).returning(leasedJobColumns);
    return job ? leasedJobFrom(job) : null;
  }

  async complete(job: LeasedTaskRunJob): Promise<void> {
    await this.database.update(taskRunJobs).set({status: "completed", lease_expires_at: null,
      updated_at: sql`CURRENT_TIMESTAMP`}).where(leasedJobMatching(this.database, job));
  }

  /** Ein geworfener Fehler beendet den Job endgültig: Eine Wiederholung würde Bausteine mit Nebenwirkungen erneut ausführen. */
  async fail(job: LeasedTaskRunJob): Promise<void> {
    await this.database.update(taskRunJobs).set({status: "failed", lease_expires_at: null,
      updated_at: sql`CURRENT_TIMESTAMP`}).where(leasedJobMatching(this.database, job));
  }

  /**
   * Ein abgelaufener Lease bedeutet, dass der Prozess während des Jobs abgestürzt ist; `claimNext`
   * holt solche Jobs erneut ab. Hat ein Job alle Versuche verbraucht, wird er hier aufgegeben,
   * damit ein Run, der die Runtime jedes Mal abstürzen lässt, nicht endlos neu startet.
   */
  async abandonExhaustedLeases(maximumAttempts: number): Promise<LeasedTaskRunJob[]> {
    const abandonedJobs = await this.database.update(taskRunJobs).set({status: "failed", lease_expires_at: null, updated_at: sql`CURRENT_TIMESTAMP`}).where(and(
      eq(taskRunJobs.status, "leased"),
      lte(taskRunJobs.lease_expires_at, sql`CURRENT_TIMESTAMP`),
      gte(taskRunJobs.attempts, maximumAttempts),
    )).returning(leasedJobColumns);
    return abandonedJobs.map(leasedJobFrom);
  }

  async nextClaimableDelayMs(): Promise<number | null> {
    const row = await this.database.select({delay_ms: sql<number | null>`MAX(0,
      (unixepoch(MIN(CASE WHEN ${taskRunJobs.status} = 'queued'
        THEN ${taskRunJobs.available_at} ELSE ${taskRunJobs.lease_expires_at} END)) - unixepoch('now')) * 1000)`})
      .from(taskRunJobs).where(inArray(taskRunJobs.status, ["queued", "leased"])).get();
    return row?.delay_ms ?? null;
  }
}

function leasedJobMatching(database: RuntimeExecutor, job: LeasedTaskRunJob) {
  return and(eq(taskRunJobs.id, job.jobId), eq(taskRunJobs.status, "leased"),
    inArray(taskRunJobs.run_id, teamRunId(database, job.teamId, job.runId)));
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
