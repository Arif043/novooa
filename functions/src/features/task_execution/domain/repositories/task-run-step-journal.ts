import {type NodeExecutionResult} from "../entities/task.js";
import {type TaskRunStepKey} from "../entities/task-run-step-key.js";

/**
 * Hält die Ergebnisse abgeschlossener Baustein-Schritte eines Runs fest. Wird ein Run nach einem
 * Absturz wiederholt, übernimmt der Runner diese Ergebnisse, statt die Bausteine — und ihre
 * Seiteneffekte — erneut auszuführen.
 */
export interface TaskRunStepJournal {
  find(key: TaskRunStepKey): Promise<NodeExecutionResult | null>;
  /** Idempotent: Ein bereits vorhandener Eintrag für denselben Key bleibt unverändert. */
  record(key: TaskRunStepKey, result: NodeExecutionResult): Promise<void>;
  clear(teamId: string, runId: string): Promise<void>;
}
