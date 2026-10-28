import {formatTaskFinished} from "./structured-logger.js";
import {type TaskGraphInput, type TaskGraphOutput} from "./task-definition.js";
import {completedOutput, type NodeRunState, pausedOutput} from "./task-graph-state.js";
import {type TaskGraphRuntime} from "./task-graph-runtime.js";

/** Das Ergebnis eines ganzen Laufs: pausiert an einer Freigabe oder abgeschlossen (mit Protokoll). */
export function finishedOutput(input: TaskGraphInput, runState: NodeRunState, runtime: TaskGraphRuntime): TaskGraphOutput {
  if (runState.status === "waitingForApproval") return pausedOutput(input, runState);
  const results = runState.nodeResults;
  const output = completedOutput(input, results);
  runtime.logger.readableInfo(formatTaskFinished(
    output.taskId,
    results.filter((result) => result.status === "executed").length,
    results.filter((result) => result.status === "skipped").length,
    output.finalOutput.length,
  ));
  return output;
}
