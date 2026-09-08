import {randomUUID} from "node:crypto";
import {
  type TaskRunDispatch,
} from "../../domain/usecases/task-workflow.js";
import {
  type LocalSqlDatabase,
  type SqlRow,
} from "../../../../shared/local/local-sql-database.js";

type TaskRunJobRow = SqlRow & {
  id: string;
  team_id: string;
  run_id: string;
  mode: "start" | "resume";
  attempts: number;
};

export type LeasedTaskRunJob = TaskRunDispatch & {
  jobId: string;
  attempt: number;
};

export class SQLiteTaskRunJobStore {
  constructor(
    private readonly database: LocalSqlDatabase,
    private readonly leaseSeconds = 60,
  ) {}

  async enqueue(input: TaskRunDispatch): Promise<void> {
    await this.database.run(enqueueSql, [
      randomUUID(), input.teamId, input.runId, input.mode,
    ]);
  }

  async claimNext(): Promise<LeasedTaskRunJob | null> {
    return this.database.transaction(async () => {
      const job = await this.database.get<TaskRunJobRow>(nextJobSql);
      if (job === null) return null;
      await this.database.run(leaseJobSql(this.leaseSeconds), [job.id]);
      return leasedJobFrom(job);
    });
  }

  async complete(job: LeasedTaskRunJob): Promise<void> {
    await this.database.run(completeJobSql, [job.jobId]);
  }

  async retryOrFail(job: LeasedTaskRunJob, maximumAttempts: number): Promise<void> {
    if (job.attempt >= maximumAttempts) {
      await this.database.run(failJobSql, [job.jobId]);
      return;
    }
    await this.database.run(retryJobSql(backoffSecondsFor(job.attempt)), [job.jobId]);
  }
}

const enqueueSql = `INSERT INTO task_run_jobs(
  id, team_id, run_id, mode, status, attempts, available_at
) VALUES (?, ?, ?, ?, 'queued', 0, CURRENT_TIMESTAMP)
ON CONFLICT(team_id, run_id) DO UPDATE SET
  mode = excluded.mode,
  status = 'queued',
  attempts = 0,
  available_at = CURRENT_TIMESTAMP,
  lease_expires_at = NULL,
  updated_at = CURRENT_TIMESTAMP`;

const nextJobSql = `SELECT id, team_id, run_id, mode, attempts
  FROM task_run_jobs
  WHERE (status = 'queued' AND available_at <= CURRENT_TIMESTAMP)
    OR (status = 'leased' AND lease_expires_at <= CURRENT_TIMESTAMP)
  ORDER BY available_at, created_at
  LIMIT 1`;

const completeJobSql = `UPDATE task_run_jobs SET status = 'completed',
  lease_expires_at = NULL, updated_at = CURRENT_TIMESTAMP
  WHERE id = ? AND status = 'leased'`;

const failJobSql = `UPDATE task_run_jobs SET status = 'failed',
  lease_expires_at = NULL, updated_at = CURRENT_TIMESTAMP
  WHERE id = ? AND status = 'leased'`;

function leaseJobSql(leaseSeconds: number): string {
  return `UPDATE task_run_jobs SET status = 'leased', attempts = attempts + 1,
    lease_expires_at = datetime('now', '+${leaseSeconds} seconds'),
    updated_at = CURRENT_TIMESTAMP WHERE id = ?`;
}

function retryJobSql(backoffSeconds: number): string {
  return `UPDATE task_run_jobs SET status = 'queued',
    available_at = datetime('now', '+${backoffSeconds} seconds'),
    lease_expires_at = NULL, updated_at = CURRENT_TIMESTAMP
    WHERE id = ? AND status = 'leased'`;
}

function leasedJobFrom(row: TaskRunJobRow): LeasedTaskRunJob {
  return {
    jobId: row.id,
    teamId: row.team_id,
    runId: row.run_id,
    mode: row.mode,
    attempt: row.attempts + 1,
  };
}

function backoffSecondsFor(attempt: number): number {
  return Math.min(30 * 2 ** (attempt - 1), 300);
}
