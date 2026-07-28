import {
  type CompletedTaskGraphOutput,
  type NodeExecutionResult,
} from "../entities/task.js";
import {type TaskRunDocument} from "./task-run-store.js";

export type TaskActivityInput = {
  run: TaskRunDocument;
  status: "started" | "succeeded" | "failed";
  input?: string;
  output?: CompletedTaskGraphOutput;
  message?: string;
};

export interface ActivityStore {
  writeNodeActivities(
    teamId: string,
    run: TaskRunDocument,
    results: NodeExecutionResult[],
  ): Promise<void>;
  writeTaskActivity(
    teamId: string,
    input: TaskActivityInput,
  ): Promise<void>;
}
