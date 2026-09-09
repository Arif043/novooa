import {
  type TaskRunDispatch,
} from "../../domain/usecases/task-workflow.js";
import {
  type LeasedTaskRunJob,
  type SQLiteTaskRunJobStore,
} from "./sqlite-task-run-job-store.js";

export type PollingTaskRunWorkerOptions = {
  pollIntervalMs?: number;
  maximumAttempts?: number;
  canProcess?: () => boolean;
  onFailure?: (job: LeasedTaskRunJob, error: unknown) => void;
};

export class PollingTaskRunWorker {
  private readonly pollIntervalMs: number;
  private readonly maximumAttempts: number;
  private readonly canProcess: () => boolean;
  private readonly onFailure: (job: LeasedTaskRunJob, error: unknown) => void;
  private timer: NodeJS.Timeout | undefined;
  private processing: Promise<void> | undefined;

  constructor(
    private readonly jobStore: SQLiteTaskRunJobStore,
    private readonly dispatch: (input: TaskRunDispatch) => Promise<void>,
    options: PollingTaskRunWorkerOptions = {},
  ) {
    this.pollIntervalMs = options.pollIntervalMs ?? 1000;
    this.maximumAttempts = options.maximumAttempts ?? 3;
    this.canProcess = options.canProcess ?? (() => true);
    this.onFailure = options.onFailure ?? (() => undefined);
  }

  start(): void {
    if (this.timer !== undefined) return;
    this.timer = setInterval(() => this.requestProcessing(), this.pollIntervalMs);
    this.requestProcessing();
  }

  async processOne(): Promise<void> {
    if (this.processing !== undefined) return this.processing;
    this.processing = this.processNext().finally(() => {
      this.processing = undefined;
    });
    return this.processing;
  }

  async stop(): Promise<void> {
    if (this.timer !== undefined) clearInterval(this.timer);
    this.timer = undefined;
    await this.processing;
  }

  private requestProcessing(): void {
    void this.processOne();
  }

  private async processNext(): Promise<void> {
    if (!this.canProcess()) return;
    const job = await this.jobStore.claimNext();
    if (job === null) return;
    try {
      await this.dispatch(job);
      await this.jobStore.complete(job);
    } catch (error) {
      this.onFailure(job, error);
      await this.jobStore.retryOrFail(job, this.maximumAttempts);
    }
  }
}
