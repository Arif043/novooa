import {type TaskRunStepKey, TaskRunStepScope} from "../../../domain/entities/task-run-step-key.js";
import {type TaskRunStepJournal} from "../../../domain/repositories/task-run-step-journal.js";
import {type NodeExecutionResult, type TaskGraphInput} from "./task-definition.js";
import {type ApplicationLogger} from "../../../../../shared/logging/application-logger.js";

export type JournaledStep = {
  journal: TaskRunStepJournal;
  key: TaskRunStepKey;
};

/** Ohne Journal (Cloud) oder ohne Run (Testlauf) gibt es keinen Geltungsbereich: Schritte laufen ungespeichert. */
export function rootStepScope(
  input: TaskGraphInput,
  journal: TaskRunStepJournal | undefined,
): TaskRunStepScope | undefined {
  if (journal === undefined || input.runId === undefined) return undefined;
  return TaskRunStepScope.root(input.teamId, input.runId);
}

export function journaledStep(
  journal: TaskRunStepJournal | undefined,
  stepScope: TaskRunStepScope | undefined,
  nodeId: string,
): JournaledStep | undefined {
  if (stepScope === undefined || journal === undefined) return undefined;
  return {journal, key: stepScope.forNode(nodeId)};
}

/**
 * Übernimmt das Ergebnis eines Schritts, den ein früherer Versuch dieses Runs schon abgeschlossen
 * hat; sonst wird er ausgeführt und sein Ergebnis festgehalten. Nur ausgeführte Schritte zählen:
 * Übersprungene ergeben sich beim Wiederholen neu, und Freigaben setzen über den Resume-Zustand fort.
 */
export async function runJournaledNode(
  step: JournaledStep | undefined,
  execute: () => Promise<NodeExecutionResult>,
  logger: ApplicationLogger,
): Promise<NodeExecutionResult> {
  if (step === undefined) return execute();
  const recorded = await step.journal.find(step.key);
  if (recorded !== null) {
    logger.readableInfo(`Baustein ${recorded.nodeId}: Ergebnis aus vorherigem Versuch übernommen.`, "task_run_step.reused");
    return recorded;
  }
  const result = await execute();
  if (result.status === "executed") await step.journal.record(step.key, result);
  return result;
}
