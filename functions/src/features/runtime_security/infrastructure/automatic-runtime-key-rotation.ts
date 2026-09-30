import {type RotateRuntimeMasterKeyIfDue} from "../domain/usecases/rotate-runtime-master-key-if-due.js";

export type RotationTimer = {cancel(): void};
export type RotationScheduler = (callback: () => void, delayMs: number) => RotationTimer;
export type RotationLog = (event: string, details: Record<string, unknown>) => void;
const dailyCheckMs = 24 * 60 * 60 * 1000;
const retryDelayMs = 5 * 60 * 1000;

export class AutomaticRuntimeKeyRotation {
  private timer: RotationTimer | undefined;
  private pending: Promise<void> | undefined;
  private stopped = true;

  constructor(
    private readonly workflow: RotateRuntimeMasterKeyIfDue,
    private readonly schedule: RotationScheduler,
    private readonly log: RotationLog,
    private readonly now: () => Date,
  ) {}

  start(): void {
    if (!this.stopped) return;
    this.stopped = false;
    this.run();
  }

  async stop(): Promise<void> {
    this.stopped = true;
    this.timer?.cancel();
    await this.pending;
  }

  private run(): void {
    this.pending = this.check().finally(() => { this.pending = undefined; });
  }

  private async check(): Promise<void> {
    try {
      const rotation = await this.workflow.execute();
      if (rotation.rotatedSecrets !== null) {
        this.log("local_runtime.master_key_rotated", {rotatedSecrets: rotation.rotatedSecrets});
      }
      this.scheduleCheck(Math.max(1, Math.min(dailyCheckMs, rotation.nextCheckAt.getTime() - this.now().getTime())));
    } catch (error) {
      this.log("local_runtime.master_key_rotation_failed", {message: error instanceof Error ? error.message : "Rotation fehlgeschlagen."});
      this.scheduleCheck(retryDelayMs);
    }
  }

  private scheduleCheck(delayMs: number): void {
    if (!this.stopped) this.timer = this.schedule(() => this.run(), delayMs);
  }
}
