export type TaskRunDispatchMode = "start" | "resume";

export type TaskRunDispatchInput = {
  teamId: string;
  runId: string;
  mode: TaskRunDispatchMode;
};

export interface TaskRunDispatcher {
  dispatchTaskRun(input: TaskRunDispatchInput): Promise<void>;
}
