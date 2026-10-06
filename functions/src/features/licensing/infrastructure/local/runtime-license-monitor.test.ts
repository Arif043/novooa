import assert from "node:assert/strict";
import test from "node:test";
import {type RuntimeLicenseCheck} from "../../domain/entities/runtime-license-verification.js";
import {RuntimeLicenseMonitor} from "./runtime-license-monitor.js";

const minute = 60 * 1000;

/** Hält geplante Prüfungen fest, statt echte Timer zu starten. */
class ManualScheduler {
  readonly delays: number[] = [];
  private pending: (() => void) | undefined;
  cancelled = 0;

  readonly schedule = (callback: () => void, delayMs: number) => {
    this.delays.push(delayMs);
    this.pending = callback;
    return {cancel: () => { this.cancelled += 1; this.pending = undefined; }};
  };

  async runNext(): Promise<void> {
    const callback = this.pending;
    this.pending = undefined;
    callback?.();
    await new Promise((resolve) => setImmediate(resolve));
  }
}

function monitorWith(scheduler: ManualScheduler, check: () => Promise<RuntimeLicenseCheck>, random: () => number) {
  const reports: string[] = [];
  const monitor = new RuntimeLicenseMonitor({
    check, report: (event) => reports.push(event), schedule: scheduler.schedule, random,
  });
  return {monitor, reports};
}

test("spreads checks with up to 15 minutes of jitter around an hourly interval", async () => {
  const scheduler = new ManualScheduler();
  const randoms = [0.5, 0, 0.999];
  const {monitor} = monitorWith(scheduler, async () => "active", () => randoms.shift() ?? 0);

  monitor.start();
  await scheduler.runNext();
  await scheduler.runNext();

  assert.deepEqual(scheduler.delays.slice(0, 3), [7.5 * minute, 60 * minute, Math.floor(60 * minute + 0.999 * 15 * minute)]);
  await monitor.stop();
});

test("reports a revoked license and keeps checking afterwards", async () => {
  const scheduler = new ManualScheduler();
  const {monitor, reports} = monitorWith(scheduler, async () => "revoked", () => 0);

  monitor.start();
  await scheduler.runNext();

  assert.deepEqual(reports, ["local_runtime.license_revoked"]);
  assert.equal(scheduler.delays.length, 2);
  await monitor.stop();
});

test("a failing check is reported and the next check is still scheduled", async () => {
  const scheduler = new ManualScheduler();
  const {monitor, reports} = monitorWith(scheduler, async () => { throw new Error("offline"); }, () => 0);

  monitor.start();
  await scheduler.runNext();

  assert.deepEqual(reports, ["local_runtime.license_check_failed"]);
  assert.equal(scheduler.delays.length, 2);
  await monitor.stop();
});

test("stop cancels the pending check and schedules nothing more", async () => {
  const scheduler = new ManualScheduler();
  let checks = 0;
  const {monitor} = monitorWith(scheduler, async () => { checks += 1; return "active"; }, () => 0);

  monitor.start();
  await monitor.stop();
  await scheduler.runNext();

  assert.equal(scheduler.cancelled, 1);
  assert.equal(checks, 0);
  assert.equal(scheduler.delays.length, 1);
});
