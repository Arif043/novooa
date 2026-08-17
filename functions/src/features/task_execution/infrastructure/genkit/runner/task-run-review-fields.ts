import {type WaitingTaskGraphOutput} from "../../../domain/entities/task.js";
import {type TaskRunInteraction} from "../../../domain/entities/task-run-interaction.js";
import {textOutputFromResult} from "./node-executor.js";

export function reviewFieldsFrom(output: WaitingTaskGraphOutput) {
  const result = output.resumeState.nodeResults.find(
    (item) => item.nodeId === output.resumeState.waitingNodeId,
  );
  return {
    instruction: result?.message ?? "Prüfe das Ergebnis und gib es frei.",
    output: result === undefined ? output.finalOutput : textOutputFromResult(result),
    interaction: interactionFor(result),
  };
}

function interactionFor(
  result: WaitingTaskGraphOutput["resumeState"]["nodeResults"][number] | undefined,
): TaskRunInteraction {
  if (result?.interaction !== undefined) return result.interaction;
  if (result?.dialogInput !== undefined) {
    return {kind: "dialogInput", ...result.dialogInput};
  }
  return {kind: "approval", instruction: result?.message ?? "Prüfe das Ergebnis und gib es frei."};
}
