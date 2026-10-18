import {type ConsoleOutput, type NodeExecutionResult, type WorkflowPrimitive} from "./task.js";

/** Der Baustein, an dem der Lauf gescheitert ist: Position (ID), Art, Meldung und seine Ausgabe bis dahin. */
export type FailedNode = {
  nodeId: string;
  primitive: WorkflowPrimitive;
  message: string;
  /** Stabiler Fehlercode, den der Client übersetzt; fehlt, wenn nur der Text bekannt ist. */
  failureCode?: string;
  /** Felder für die Übersetzung des Codes, z. B. Operator und erhaltener Wert. */
  failureDetails?: Record<string, string>;
  console?: ConsoleOutput;
};

/**
 * Ein Baustein ist gescheitert und damit der Lauf. Enthält, was die Aktivitäten brauchen: die
 * Bausteine, die vorher erfolgreich waren, und den gescheiterten Baustein. `cause` ist der
 * ursprüngliche Fehler; er dient nur dem Protokoll und der Weitergabe an die Infrastruktur.
 */
export class NodeExecutionFailure {
  constructor(
    readonly failedNode: FailedNode,
    readonly completedNodeResults: NodeExecutionResult[],
    readonly cause: unknown,
  ) {}

  get message(): string {
    return this.failedNode.message;
  }
}
