export const taskRunFailureCodes = [
  "invalidRequest",
  "invalidTaskId",
  "invalidReviewDecision",
  "invalidFormValues",
] as const;

export type TaskRunFailureCode = (typeof taskRunFailureCodes)[number];

export class TaskRunFailure {
  constructor(
    readonly code: TaskRunFailureCode,
    readonly message: string,
  ) {}
}
