import {
  type CompletedTaskGraphOutput,
  type NodeExecutionResult,
} from "../entities/task.js";
import {type FailedNode} from "../services/run-failure-details.js";
import {type TaskRunDocument} from "./task-run-store.js";

export type TaskActivityInput = {
  run: TaskRunDocument;
  status: "started" | "succeeded" | "failed";
  input?: string;
  output?: CompletedTaskGraphOutput;
  message?: string;
};

export interface ActivityStore {
  /** Der Baustein, an dem ein Lauf gescheitert ist, steht an seiner Position mit Meldung und Ausgabe. */
  writeFailedNodeActivity(
    teamId: string,
    run: TaskRunDocument,
    failedNode: FailedNode,
  ): Promise<void>;
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
