export type TaskWorkflowContext = {
  uid: string;
};

export type StartTaskWorkflowInput = {
  taskId: string;
  context: string;
};

export type StartTaskWorkflowOutput = {
  runId: string;
  taskId: string;
  status: "queued";
};

export type ReviewTaskWorkflowInput = {
  runId: string;
  decision: "approve" | "reject";
  output: string;
  formValues: Record<string, unknown>;
};

export type ReviewTaskWorkflowOutput = {
  runId: string;
  status: "queued" | "rejected";
};

export type TaskRunDispatch = {
  teamId: string;
  runId: string;
  mode: "start" | "resume";
};

export interface TaskWorkflow {
  start(
    input: StartTaskWorkflowInput,
    context: TaskWorkflowContext,
  ): Promise<StartTaskWorkflowOutput>;
  review(
    input: ReviewTaskWorkflowInput,
    context: TaskWorkflowContext,
  ): Promise<ReviewTaskWorkflowOutput>;
  dispatch(input: TaskRunDispatch): Promise<void>;
}
