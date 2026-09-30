export type RuntimeRotationStatus = {lastRotatedAt: string; rotationPending: boolean};

export interface RuntimeRotationSchedule {
  rotationStatus(): Promise<RuntimeRotationStatus>;
}
