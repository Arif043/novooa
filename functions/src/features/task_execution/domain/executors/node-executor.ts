import {type RunEffectRecorder} from "../services/run-effect-recorder.js";
import {type Result} from "neverthrow";
import {type NodeFailure} from "../entities/node-failure.js";
import {type SpeechTranscriber} from "../../../speech_transcription/domain/repositories/speech-transcriber.js";
import {type SpeechSynthesizer} from "../../../speech_synthesis/domain/repositories/speech-synthesizer.js";
import {
  type ConsoleOutput,
  type NodeExecutionResult,
  type NodeOutputValue,
  type FileReference,
  type TaskDefinition,
  type WorkflowGraph,
  type WorkflowNode,
} from "../entities/task.js";
import {type TaskRunInteraction} from "../entities/task-run-interaction.js";
import {type TeamworkConversationEntry} from "../entities/teamwork-conversation.js";
import {type WorkflowInputValue} from "../entities/workflow-value.js";
import {type TeamFileContentReader} from "../../../files/domain/repositories/team-file-content-reader.js";
import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {type ModelInference} from "../../../machine_learning/domain/repositories/model-inference.js";
import {type TaskMessageSender} from "../repositories/task-message-sender.js";
import {type DocumentStore} from "../../../data/domain/repositories/document-store.js";
import {type OutboundHttpClient} from "../../../connections/domain/repositories/outbound-http-client.js";
import {type TeamNotificationSender} from "../../../notifications/domain/repositories/team-notification-sender.js";

export type TemplateExpressionResolver = {
  /** Der Wert hinter einem Pfad (`rechnung`, `rechnung.summe`) samt Typ; `undefined`, wenn es ihn nicht gibt. */
  typedValueAt(path: string): WorkflowInputValue | undefined;
  resolveText(template: string): string;
  resolveTextWithoutMediaReferences(template: string): string;
  resolveValue(template: string): unknown;
  resolveMediaReferences(template: string): FileReference[];
};

export type WorkflowExecutionScope = {
  global?: Record<string, unknown>;
  iteration?: {
    index: number;
    value: unknown;
  };
};

export type WorkflowGraphRunner = (
  graph: WorkflowGraph,
  /** Zusätzlicher Geltungsbereich des Teilgraphen, z. B. das aktuelle Element einer Schleife. */
  scope?: WorkflowExecutionScope,
) => Promise<Result<NodeExecutionResult[], NodeFailure>>;

/**
 * Dienste, die ein Lauf unverändert an jeden Baustein durchreicht. Wer einen neuen
 * Dienst für Executoren braucht, ergänzt ihn nur hier: Laufzeit und Kontext
 * übernehmen ihn automatisch.
 */
export type TaskRunServices = {
  fileContentReader: TeamFileContentReader;
  messageSender: TaskMessageSender;
  documentStore: DocumentStore;
  modelInference: ModelInference;
  /** Sprachausgabe über verbundene Sprachmodelle; fehlt in Umgebungen ohne Sprachmodell-Katalog. */
  speechSynthesizer?: SpeechSynthesizer;
  speechTranscriber?: SpeechTranscriber;
  teamNotificationSender: TeamNotificationSender;
  /** Sendet HTTP-Anfragen (Baustein `httpRequest`); fehlt in Umgebungen ohne Verbindungen (Cloud). */
  outboundHttpClient?: OutboundHttpClient;
};

export type TaskRunContext = TaskRunServices & {
  rootTask: TaskDefinition;
  currentGraph: WorkflowGraph;
  teamId: string;
  input: Record<string, unknown>;
  scope: WorkflowExecutionScope;
  results: Map<string, NodeExecutionResult>;
  runGraph: WorkflowGraphRunner;
  templateExpressionResolver: TemplateExpressionResolver;
  teamFileStore: TeamFileStore;
  /** Folgen dieses Bausteins. Ports zeichnen selbst auf; melden muss nur, wer an ihnen vorbei
   * nach außen wirkt (Plugins). */
  effects: RunEffectRecorder;
};

/** Ergebnis eines Bausteins oder, als Wert, warum er gescheitert ist. */
export type NodeResultOrFailure = Result<NodeExecutionResult, NodeFailure>;

export type NodeExecutor = {
  primitive: WorkflowNode["primitive"];
  execute(
    node: WorkflowNode,
    runContext: TaskRunContext,
  ): Promise<NodeResultOrFailure>;
};

export function executedNode(
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
  options: {
    selectedNodeId?: string | null;
    selection?: {
      selectedBranchId?: string | null;
      selectedBranchLabel?: string | null;
    };
    console?: ConsoleOutput;
    conversation?: TeamworkConversationEntry[];
  } = {},
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    outputs,
    console: options.console,
    ...(options.conversation ? {conversation: options.conversation} : {}),
    selectedNodeId: options.selectedNodeId,
    selectedBranchId: options.selection?.selectedBranchId,
    selectedBranchLabel: options.selection?.selectedBranchLabel,
  };
}

export function skippedNode(node: WorkflowNode): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "skipped",
    outputs: {},
    message: "Baustein-Executor ist noch nicht implementiert.",
  };
}

export function waitingForInteractionNode(
  node: WorkflowNode,
  outputs: Record<string, NodeOutputValue>,
  interaction: TaskRunInteraction,
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "waitingForApproval",
    outputs,
    message: interaction.instruction,
    interaction,
  };
}

export function stringOutput(value: string): NodeOutputValue {
  return {type: "string", value};
}

export function datetimeOutput(value: string): NodeOutputValue {
  return {type: "datetime", value};
}

export function textOutputs(text: string): Record<string, NodeOutputValue> {
  if (text.trim().length === 0) return {};
  return {value: stringOutput(text)};
}

export function textOutputFromResult(result: NodeExecutionResult): string {
  const value = primaryOutputFromResult(result);
  return value === undefined ? "" : textForOutputValue(value);
}

// Bausteine mit Feldern (strukturierter Prompt, Dialog, Script) haben keinen
// Hauptwert `value`; dann stehen alle Felder zusammen für den Baustein.
function primaryOutputFromResult(
  result: NodeExecutionResult,
): NodeOutputValue | undefined {
  if (result.outputs.value !== undefined) return result.outputs.value;
  const entries = Object.entries(result.outputs);
  if (entries.length <= 1) return entries[0]?.[1];
  return {type: "json", value: Object.fromEntries(entries.map(([key, output]) => [key, output.value]))};
}

function textForOutputValue(value: NodeOutputValue): string {
  if (value.type === "string" || value.type === "datetime") return value.value;
  if (value.type === "number" || value.type === "boolean") return String(value.value);
  if (value.type === "json") return JSON.stringify(value.value);
  if (value.type === "media") return `Bild: ${value.value.displayName}`;
  if (value.type === "audio") return `Audio: ${value.value.displayName}`;
  if (value.type === "table") {
    return `Tabelle mit ${value.value.rows.length} Zeile(n)`;
  }
  return `Datei: ${value.value.displayName}`;
}

export function parentResultsFor(
  node: WorkflowNode,
  graph: WorkflowGraph,
  results: Map<string, NodeExecutionResult>,
) {
  return graph.edges
    .filter((edge) => edge.to === node.id)
    .map((edge) => ({edge, result: results.get(edge.from)}))
    .filter((parent) => parent.result !== undefined) as {
      edge: WorkflowGraph["edges"][number];
      result: NodeExecutionResult;
    }[];
}
