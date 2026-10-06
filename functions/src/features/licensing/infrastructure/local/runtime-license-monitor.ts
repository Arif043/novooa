import {type RuntimeLicenseCheck} from "../../domain/entities/runtime-license-verification.js";

export type ScheduledCheck = {cancel(): void};
export type CheckScheduler = (callback: () => void, delayMs: number) => ScheduledCheck;

export type RuntimeLicenseMonitorOptions = {
  /** Prüft die Aktivierung beim Gateway; wirft, wenn es kein eindeutiges Urteil gibt. */
  check: () => Promise<RuntimeLicenseCheck>;
  report: (event: string, details?: Record<string, unknown>) => void;
  intervalMs?: number;
  /** Zufällige Streuung je Prüfung, damit nicht alle Runtimes gleichzeitig anfragen. */
  jitterMs?: number;
  random?: () => number;
  schedule?: CheckScheduler;
};

const defaultIntervalMs = 60 * 60 * 1000;
const defaultJitterMs = 15 * 60 * 1000;

/**
 * Prüft die Lizenz regelmäßig beim Gateway, damit eine in der Cloud gelöschte
 * oder freigegebene Lizenz die Runtime sperrt. Die erste Prüfung folgt
 * innerhalb der Streuung nach dem Start, danach alle `intervalMs` plus
 * Streuung. Ist das Gateway nicht erreichbar, läuft die Runtime weiter.
 */
export class RuntimeLicenseMonitor {
  private readonly intervalMs: number;
  private readonly jitterMs: number;
  private readonly random: () => number;
  private readonly schedule: CheckScheduler;
  private next: ScheduledCheck | undefined;
  private running: Promise<void> | undefined;
  private started = false;
  private stopped = false;

  constructor(private readonly options: RuntimeLicenseMonitorOptions) {
    this.intervalMs = options.intervalMs ?? defaultIntervalMs;
    this.jitterMs = options.jitterMs ?? defaultJitterMs;
    this.random = options.random ?? Math.random;
    this.schedule = options.schedule ?? unrefTimeout;
  }

  start(): void {
    if (this.started || this.stopped) return;
    this.started = true;
    this.scheduleIn(this.jitter());
  }

  async stop(): Promise<void> {
    this.stopped = true;
    this.next?.cancel();
    this.next = undefined;
    await this.running;
  }

  private scheduleIn(delayMs: number): void {
    if (this.stopped) return;
    this.next = this.schedule(() => void this.tick(), delayMs);
  }

  private async tick(): Promise<void> {
    this.running = this.checkOnce();
    await this.running;
    this.running = undefined;
    this.scheduleIn(this.intervalMs + this.jitter());
  }

  private async checkOnce(): Promise<void> {
    try {
      const result = await this.options.check();
      if (result === "revoked") this.options.report("local_runtime.license_revoked");
    } catch (error) {
      this.options.report("local_runtime.license_check_failed", {
        message: error instanceof Error ? error.message : String(error),
      });
    }
  }

  private jitter(): number {
    return Math.floor(this.random() * this.jitterMs);
  }
}

function unrefTimeout(callback: () => void, delayMs: number): ScheduledCheck {
  // Der Timer allein soll den Prozess nicht am Beenden hindern.
  const timer = setTimeout(callback, delayMs);
  timer.unref();
  return {cancel: () => clearTimeout(timer)};
}
