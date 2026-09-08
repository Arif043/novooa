export type PollingTaskTriggerWorkerOptions = {pollIntervalMs?: number};

export class PollingTaskTriggerWorker {
  private readonly pollIntervalMs: number;
  private processing: Promise<void> | undefined;
  private timer: NodeJS.Timeout | undefined;

  constructor(
    private readonly processDueTriggers: () => Promise<void>,
    options: PollingTaskTriggerWorkerOptions = {},
  ) {
    this.pollIntervalMs = options.pollIntervalMs ?? 30_000;
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
    void this.processOnce();
  }
}
