import {
  type NodeExecutionResult,
  type TaskDefinition,
  type WorkflowNode,
} from "./task-definition.js";
import {textOutputFromResult} from "../../../domain/executors/node-executor.js";
import {
  errorMessage,
  formatConfig,
  formatDuration,
  formatInline,
  indent,
  preview,
  redactedConfig,
  selectedTargetFor,
  stackLine,
  statusLabel,
  valueOrDash,
} from "./structured-log-format-utils.js";

type LogData = Record<string, unknown>;

export function taskSummary(task: TaskDefinition): LogData {
  return {
    taskId: task.id,
    title: task.title,
    nodeCount: task.nodes.length,
    edgeCount: task.edges.length,
  };
}

export function nodeSummary(node: WorkflowNode): LogData {
  return {
    nodeId: node.id,
    primitive: node.primitive,
    title: node.title,
  };
}

export function nodeAttributes(node: WorkflowNode): LogData {
  return {
    id: node.id,
    primitive: node.primitive,
    title: node.title,
    description: node.description,
    config: redactedConfig(node.config),
  };
}

export function resultSummary(result: NodeExecutionResult): LogData {
  const output = textOutputFromResult(result);
  return {
    nodeId: result.nodeId,
    primitive: result.primitive,
    status: result.status,
    outputLength: output.length,
    selectedNodeId: result.selectedNodeId,
    selectedBranchId: result.selectedBranchId,
    selectedBranchLabel: result.selectedBranchLabel,
  };
}

export function formatTaskStarted(task: TaskDefinition, context: string): string {
  return [
    "",
    `[Aufgabe startet] ${task.title}`,
    `ID: ${task.id}`,
    `Bausteine: ${task.nodes.length} | Kanten: ${task.edges.length}`,
    `Kontext: ${valueOrDash(preview(context))}`,
  ].join("\n");
}

export function formatTaskFinished(
  taskId: string,
  executedNodeCount: number,
  skippedNodeCount: number,
  finalOutputLength: number,
): string {
  return [
    `[Aufgabe beendet] ${taskId}`,
    `Ausgeführt: ${executedNodeCount} | Übersprungen: ${skippedNodeCount}`,
    `Finale Ausgabe: ${finalOutputLength} Zeichen`,
    "",
  ].join("\n");
}

export function formatNodeHeader(input: {
  node: WorkflowNode;
  taskId: string;
  context: string;
  parentNodeIds: string[];
  skipNode: boolean;
}): string {
  return [
    "------------------------------------------------------------",
    `Baustein startet: ${input.node.title}`,
    `ID: ${input.node.id}`,
    `Typ: ${input.node.primitive}`,
    `Aufgabe: ${input.taskId}`,
    `Beschreibung: ${valueOrDash(input.node.description)}`,
    `Eltern: ${valueOrDash(input.parentNodeIds.join(", "))}`,
    `Kontext: ${valueOrDash(preview(input.context))}`,
    `Überspringen: ${input.skipNode ? "ja" : "nein"}`,
    "Konfiguration:",
    indent(formatConfig(input.node.config)),
  ].join("\n");
}

export function formatNodeTrail(input: {
  result: NodeExecutionResult;
  durationMs: number;
}): string {
  const output = textOutputFromResult(input.result);
  return [
    `Baustein beendet: ${input.result.nodeId}`,
    `Status: ${statusLabel(input.result.status)}`,
    `Dauer: ${formatDuration(input.durationMs)}`,
    `Ausgabe: ${output.length} Zeichen`,
    selectedTargetFor(input.result),
    "------------------------------------------------------------",
  ].filter(Boolean).join("\n");
}

export function formatNodeFailed(input: {
  node: WorkflowNode;
  durationMs: number;
  error: unknown;
}): string {
  return [
    `Baustein fehlgeschlagen: ${input.node.title}`,
    `ID: ${input.node.id}`,
    `Typ: ${input.node.primitive}`,
    `Dauer: ${formatDuration(input.durationMs)}`,
    `Fehler: ${errorMessage(input.error)}`,
    "------------------------------------------------------------",
  ].join("\n");
}

export function formatException(input: {
  title: string;
  error: unknown;
  context?: string[];
}): string {
  return [
    `[Fehler] ${input.title}`,
    ...input.context ?? [],
    `Ursache: ${errorMessage(input.error)}`,
    stackLine(input.error),
  ].filter(Boolean).join("\n");
}

export function formatModelCallStarted(input: {
  label: string;
  model: unknown;
  prompt: string;
  outputSchema?: string;
  /** Angehängte Bilder; sie stehen nicht im Text, sondern gehen als eigene Teile an das Modell. */
  mediaCount?: number;
  options?: Record<string, unknown>;
}): string {
  return [
    `[Modelcall startet] ${input.label}`,
    `Modell: ${formatInline(input.model)}`,
    input.options && Object.keys(input.options).length > 0 ? `Optionen: ${formatInline(input.options)}` : "",
    input.outputSchema ? `Schema: ${input.outputSchema}` : "",
    input.mediaCount ? `Bilder: ${input.mediaCount}` : "",
    "Eingabe:",
    `:${indent(input.prompt)}:`,
  ].filter(Boolean).join("\n");
}

export function formatModelCallFinished(input: {
  label: string;
  durationMs: number;
  text: string;
  output?: unknown;
}): string {
  return [
    `[Modelcall beendet] ${input.label}`,
    `Dauer: ${formatDuration(input.durationMs)}`,
    `Antwort: ${input.text.length} Zeichen`,
    `Antwort-Vorschau: ${valueOrDash(preview(input.text))}`,
    input.output === undefined ? "" : `Struktur: ${formatInline(input.output)}`,
  ].filter(Boolean).join("\n");
}
