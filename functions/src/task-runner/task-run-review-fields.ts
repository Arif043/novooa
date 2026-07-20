import {type WaitingTaskGraphOutput} from "../domain/entities/task.js";
import {textOutputFromResult} from "./node-executor.js";

export function reviewFieldsFrom(output: WaitingTaskGraphOutput) {
  const result = output.resumeState.nodeResults.find(
    (item) => item.nodeId === output.resumeState.waitingNodeId,
  );
  return {
    instruction: result?.message ?? "Prüfe das Ergebnis und gib es frei.",
    output: result === undefined ? output.finalOutput : textOutputFromResult(result),
  };
}
