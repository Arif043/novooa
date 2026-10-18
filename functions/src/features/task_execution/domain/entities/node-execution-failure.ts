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

/**
 * Die Ursache eines gescheiterten Bausteins als stabiler Code samt Rückfalltext, z. B. aus einer
 * `LanguageModelFailure`. `details` trägt die Felder, die der Client in die Übersetzung einsetzt.
 */
export type NodeFailureReason = {code: string; message: string; details?: Record<string, string>};

/**
 * Executoren melden Fehler als Exception (Vertrag von `NodeExecutor`). Hat ein Executor bereits
 * eine Failure, verpackt er sie hierin; der Runner übernimmt dann ihren Code in den `FailedNode`.
 */
export class NodeFailedError extends Error {
  constructor(readonly reason: NodeFailureReason) {
    super(reason.message);
    this.name = "NodeFailedError";
  }
}
