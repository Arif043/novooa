import {type RuntimeRotationSchedule} from "../repositories/runtime-rotation-schedule.js";
import {type RotateRuntimeMasterKey} from "./rotate-runtime-master-key.js";

export class RotateRuntimeMasterKeyIfDue {
  constructor(
    private readonly schedule: RuntimeRotationSchedule,
    private readonly rotation: RotateRuntimeMasterKey,
    private readonly now: () => Date,
  ) {}

  async execute(): Promise<{nextCheckAt: Date; rotatedSecrets: number | null}> {
    const status = await this.schedule.rotationStatus();
    const dueAt = nextRotationAt(new Date(status.lastRotatedAt));
    if (!status.rotationPending && this.now() < dueAt) return {nextCheckAt: dueAt, rotatedSecrets: null};
    const rotatedSecrets = await this.rotation.execute();
    const completed = await this.schedule.rotationStatus();
    return {nextCheckAt: nextRotationAt(new Date(completed.lastRotatedAt)), rotatedSecrets};
  }
}

export function nextRotationAt(previous: Date): Date {
  if (!Number.isFinite(previous.getTime())) throw new Error("Ungültiger Rotationszeitpunkt.");
  const next = new Date(previous);
  next.setUTCDate(1);
  next.setUTCMonth(next.getUTCMonth() + 1);
  const lastDay = new Date(Date.UTC(next.getUTCFullYear(), next.getUTCMonth() + 1, 0)).getUTCDate();
  next.setUTCDate(Math.min(previous.getUTCDate(), lastDay));
  return next;
}
