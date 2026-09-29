import {
  type NodeExecutionResult,
  type NodeOutputValue,
  type FileReference,
  type TaskDefinition,
  type WorkflowGraph,
  type WorkflowNode,
} from "../entities/task.js";
import {type TaskRunInteraction} from "../entities/task-run-interaction.js";
import {type TeamFileContentReader} from "../../../files/domain/repositories/team-file-content-reader.js";
import {type TeamFileStore} from "../../../files/domain/repositories/team-file-store.js";
import {type ModelInference} from "../../../machine_learning/domain/repositories/model-inference.js";
import {type TaskMessageSender} from "../repositories/task-message-sender.js";
import {type DocumentStore} from "../../../data/domain/repositories/document-store.js";
import {type TeamNotificationSender} from "../../../notifications/domain/repositories/team-notification-sender.js";

export type TaskVariables = Record<string, unknown>;

export type TemplateExpressionResolver = {
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

export type WorkflowGraphInput = {scope?: WorkflowExecutionScope};

export type WorkflowGraphRunner = (
  graph: WorkflowGraph,
  context: string,
  input?: WorkflowGraphInput,
) => Promise<NodeExecutionResult[]>;

export type TaskRunContext = {
  context: string;
  variables: TaskVariables;
  rootTask: TaskDefinition;
  currentGraph: WorkflowGraph;
  teamId: string;
  input: Record<string, unknown>;
  scope: WorkflowExecutionScope;
  results: Map<string, NodeExecutionResult>;
  runGraph: WorkflowGraphRunner;
  templateExpressionResolver: TemplateExpressionResolver;
  teamFileStore: TeamFileStore;
  fileContentReader: TeamFileContentReader;
  messageSender: TaskMessageSender;
  documentStore: DocumentStore;
  modelInference: ModelInference;
  teamNotificationSender: TeamNotificationSender;
};

export type NodeExecutor = {
  primitive: WorkflowNode["primitive"];
  execute(
    node: WorkflowNode,
    runContext: TaskRunContext,
  ): Promise<NodeExecutionResult>;
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
    variables?: TaskVariables;
  } = {},
): NodeExecutionResult {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    status: "executed",
    outputs,
    variables: options.variables,
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

function primaryOutputFromResult(
  result: NodeExecutionResult,
): NodeOutputValue | undefined {
  if (result.outputs.value !== undefined) return result.outputs.value;
  const outputs = Object.values(result.outputs);
  return outputs.length === 1 ? outputs[0] : undefined;
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
