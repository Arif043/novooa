import {
  type TaskRunDispatch,
} from "../../domain/usecases/task-workflow.js";
import {
  type LeasedTaskRunJob,
  type SQLiteTaskRunJobStore,
} from "./sqlite-task-run-job-store.js";
import {type LocalRuntimeRealtimeNotifier} from "../../../../shared/local/local-runtime-realtime-notifier.js";

export type TaskRunQueueWorkerOptions = {
  /** Wie oft ein Job insgesamt gestartet werden darf; weitere Versuche gibt es nur nach einem Absturz. */
  maximumAttempts?: number;
  canProcess?: () => boolean;
  onFailure?: (job: LeasedTaskRunJob, error: unknown) => void;
  /** Wird für Jobs aufgerufen, deren Versuche nach wiederholten Abstürzen aufgebraucht sind. */
  onAbandoned?: (job: LeasedTaskRunJob) => Promise<void>;
  onDrainFailure?: (error: unknown) => void;
  /**
   * Optional, damit bestehende Tests den Worker ohne Realtime-Infrastruktur
   * konstruieren können. Ein Run ändert sich nicht nur durch HTTP-Requests
   * (`/v1/task-runs`), sondern auch hier im Hintergrund — Watch-Clients
   * müssen also auch von hier benachrichtigt werden.
   */
  notifier?: LocalRuntimeRealtimeNotifier;
};

export class TaskRunQueueWorker {
  private readonly maximumAttempts: number;
  private readonly canProcess: () => boolean;
  private readonly onFailure: (job: LeasedTaskRunJob, error: unknown) => void;
  private readonly onAbandoned: (job: LeasedTaskRunJob) => Promise<void>;
  private readonly onDrainFailure: (error: unknown) => void;
  private readonly notifier: LocalRuntimeRealtimeNotifier | undefined;
  private started = false;
  private stopping = false;
  private drainRequested = false;
  private draining: Promise<void> | undefined;
  private retryTimer: NodeJS.Timeout | undefined;

  constructor(
    private readonly jobStore: SQLiteTaskRunJobStore,
    private readonly dispatch: (input: TaskRunDispatch) => Promise<void>,
    options: TaskRunQueueWorkerOptions = {},
  ) {
    this.maximumAttempts = options.maximumAttempts ?? 3;
    this.canProcess = options.canProcess ?? (() => true);
    this.onFailure = options.onFailure ?? (() => undefined);
    this.onAbandoned = options.onAbandoned ?? (async () => undefined);
    this.onDrainFailure = options.onDrainFailure ?? (() => undefined);
    this.notifier = options.notifier;
  }

  start(): void {
    if (this.started || this.stopping) return;
    this.started = true;
    this.requestDrain();
  }

  notify(): void {
    if (this.stopping) return;
    this.drainRequested = true;
    this.startDrain();
  }

  async stop(): Promise<void> {
    this.stopping = true;
    this.drainRequested = false;
    this.clearRetryTimer();
    await this.draining;
  }

  private requestDrain(): void {
    this.drainRequested = true;
    this.startDrain();
  }

  private startDrain(): void {
    if (!this.canDrain() || this.draining !== undefined) return;
    this.clearRetryTimer();
    this.draining = this.drainUntilIdle()
      .catch((error) => this.onDrainFailure(error))
      .finally(() => this.finishDrain());
  }

  private async drainUntilIdle(): Promise<void> {
    do {
      this.drainRequested = false;
      await this.drainAvailableJobs();
    } while (this.canDrain() && this.drainRequested);
    await this.scheduleNextDrain();
  }

  private async drainAvailableJobs(): Promise<void> {
    if (!this.canProcess()) return;
    while (!this.stopping) {
      await this.abandonExhaustedJobs();
      const job = await this.jobStore.claimNext();
      if (job === null) return;
      await this.process(job);
    }
  }

  private async abandonExhaustedJobs(): Promise<void> {
    const abandonedJobs = await this.jobStore.abandonExhaustedLeases(this.maximumAttempts);
    for (const job of abandonedJobs) {
      try {
        await this.onAbandoned(job);
      } catch (error) {
        this.onFailure(job, error);
      } finally {
        this.publishRunChanges();
      }
    }
  }

  private async process(job: LeasedTaskRunJob): Promise<void> {
    try {
      await this.dispatch(job);
      await this.jobStore.complete(job);
    } catch (error) {
      this.onFailure(job, error);
      await this.jobStore.fail(job);
    } finally {
      this.publishRunChanges();
    }
  }

  private publishRunChanges(): void {
    this.notifier?.publish("task-runs");
    this.notifier?.publish("task-activities");
  }

  private async scheduleNextDrain(): Promise<void> {
    if (!this.canDrain() || this.drainRequested) return;
    const delayMs = await this.jobStore.nextClaimableDelayMs();
    if (delayMs === null || !this.canDrain() || this.drainRequested) return;
    this.retryTimer = setTimeout(() => {
      this.retryTimer = undefined;
      this.requestDrain();
    }, Math.max(10, delayMs));
  }

  private finishDrain(): void {
    this.draining = undefined;
    if (this.drainRequested && this.canDrain()) this.startDrain();
  }

  private canDrain(): boolean {
    return this.started && !this.stopping;
  }

  private clearRetryTimer(): void {
    if (this.retryTimer === undefined) return;
    clearTimeout(this.retryTimer);
    this.retryTimer = undefined;
  }
}
