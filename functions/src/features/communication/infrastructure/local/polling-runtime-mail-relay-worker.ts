import {type SignedRuntimeLicense} from
  "../../../licensing/domain/entities/runtime-license-lease.js";
import {type LocalApplicationLogger} from
  "../../../../shared/logging/local-application-logger.js";
import {type RuntimeMailRelayClient} from "./runtime-mail-relay-client.js";
import {type LocalMailRelayEventProcessor} from "./local-mail-relay-event-processor.js";

export type PollingRuntimeMailRelayWorkerOptions = {
  pollIntervalMs?: number;
  canProcess?: () => boolean;
  onFailure?: (error: unknown) => void;
};

export class PollingRuntimeMailRelayWorker {
  private readonly pollIntervalMs: number;
  private readonly canProcess: () => boolean;
  private readonly onFailure: (error: unknown) => void;
  private timer: NodeJS.Timeout | undefined;
  private processing: Promise<void> | undefined;

  constructor(
    private readonly signedLicense: () => SignedRuntimeLicense | null,
    private readonly relay: RuntimeMailRelayClient,
    private readonly processor: LocalMailRelayEventProcessor,
    private readonly logger: LocalApplicationLogger,
    options: PollingRuntimeMailRelayWorkerOptions = {},
  ) {
    this.pollIntervalMs = options.pollIntervalMs ?? 10_000;
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
    this.processing = this.process().finally(() => { this.processing = undefined; });
    return this.processing;
  }

  async stop(): Promise<void> {
    if (this.timer !== undefined) clearInterval(this.timer);
    this.timer = undefined;
    await this.processing;
  }

  private async process(): Promise<void> {
    if (!this.canProcess()) return;
    const license = this.signedLicense();
    if (license === null) return;
    const deliveries = await this.relay.pull(license, 10);
    for (const delivery of deliveries) await this.processDelivery(license, delivery);
  }

  private requestProcessing(): void {
    void this.processOnce().catch(this.onFailure);
  }

  private async processDelivery(
    license: SignedRuntimeLicense,
    delivery: Awaited<ReturnType<RuntimeMailRelayClient["pull"]>>[number],
  ): Promise<void> {
    try {
      await this.processor.process(delivery);
      await this.relay.acknowledge(license, delivery);
    } catch (error) {
      this.logger.exception("local_mail_relay.delivery_failed", error, {eventId: delivery.eventId});
      await this.relay.reject(license, delivery, errorMessage(error));
    }
  }
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message.slice(0, 500) : String(error).slice(0, 500);
}
