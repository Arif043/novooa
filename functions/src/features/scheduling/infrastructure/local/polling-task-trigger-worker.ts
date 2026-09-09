export type PollingTaskTriggerWorkerOptions = {
  pollIntervalMs?: number;
  canProcess?: () => boolean;
  onFailure?: (error: unknown) => void;
};

export class PollingTaskTriggerWorker {
  private readonly pollIntervalMs: number;
  private readonly canProcess: () => boolean;
  private readonly onFailure: (error: unknown) => void;
  private processing: Promise<void> | undefined;
  private timer: NodeJS.Timeout | undefined;

  constructor(
    private readonly processDueTriggers: () => Promise<void>,
    options: PollingTaskTriggerWorkerOptions = {},
  ) {
    this.pollIntervalMs = options.pollIntervalMs ?? 30_000;
    this.canProcess = options.canProcess ?? (() => true);
    this.onFailure = options.onFailure ?? (() => undefined);
  }

  start(): void {
    if (this.timer !== undefined) return;
    this.timer = setInterval(() => this.requestProcessing(), this.pollIntervalMs);
    this.requestProcessing();
  }

  async processOnce(): Promise<void> {
    if (this.processing !== undefined) return this.processing;
    this.processing = this.processDueTriggers().finally(() => {
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
    if (!this.canProcess()) return;
    void this.processOnce().catch(this.onFailure);
  }
}
