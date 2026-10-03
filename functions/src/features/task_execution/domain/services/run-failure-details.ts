import {type ConsoleOutput, type NodeExecutionResult, type WorkflowPrimitive} from "../entities/task.js";

/** Der Baustein, an dem der Lauf gescheitert ist: Position (ID), Art, Meldung und seine Ausgabe bis dahin. */
export type FailedNode = {
  nodeId: string;
  primitive: WorkflowPrimitive;
  message: string;
  console?: ConsoleOutput;
};

/**
 * Was die Aktivitäten eines fehlgeschlagenen Laufs brauchen: die Bausteine, die vorher erfolgreich
 * waren, und der Baustein, der gescheitert ist.
 */
export type RunFailureDetails = {
  completedNodeResults: NodeExecutionResult[];
  failedNode?: FailedNode;
};

/**
 * Der Lauf schlägt fehl wie bisher; die Einzelheiten stehen neben dem Fehler und nicht darin, damit
 * Meldung, Typ und Stack des Fehlers unverändert bleiben.
 */
const detailsByError = new WeakMap<object, RunFailureDetails>();

export function attachRunFailureDetails(error: unknown, details: RunFailureDetails): unknown {
  if (error === null || typeof error !== "object") return error;
  detailsByError.set(error, details);
  return error;
}

export function runFailureDetailsOf(error: unknown): RunFailureDetails {
  if (error === null || typeof error !== "object") return {completedNodeResults: []};
  return detailsByError.get(error) ?? {completedNodeResults: []};
}
