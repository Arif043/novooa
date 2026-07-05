import {logger} from "firebase-functions";
import {
  type NodeExecutionResult,
  type TaskDefinition,
  type WorkflowNode,
} from "./task-definition.js";

export type LogData = Record<string, unknown>;

export function logInfo(event: string, data: LogData = {}): void {
  logger.info(event, {event, ...data});
}

export function logError(event: string, data: LogData = {}): void {
  logger.error(event, {event, ...data});
}

export function logReadableInfo(message: string): void {
  console.info(message);
}

export function logReadableError(message: string): void {
  console.error(message);
}

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
    config: node.config,
  };
}

export function resultSummary(result: NodeExecutionResult): LogData {
  return {
    nodeId: result.nodeId,
    primitive: result.primitive,
    status: result.status,
    outputLength: result.output.length,
    selectedNodeId: result.selectedNodeId,
    selectedBranchId: result.selectedBranchId,
    selectedBranchLabel: result.selectedBranchLabel,
  };
}

export function textSummary(text: string, field = "text"): LogData {
  return {
    [`${field}Length`]: text.length,
    [`${field}Preview`]: preview(text),
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
  return [
    `Baustein beendet: ${input.result.nodeId}`,
    `Status: ${statusLabel(input.result.status)}`,
    `Dauer: ${formatDuration(input.durationMs)}`,
    `Ausgabe: ${input.result.output.length} Zeichen`,
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

export function errorDetails(error: unknown): unknown {
  if (error instanceof Error) {
    return {name: error.name, message: error.message, stack: error.stack};
  }
  return error;
}

function preview(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > 160
    ? `${normalized.slice(0, 157)}...`
    : normalized;
}

function formatConfig(config: unknown): string {
  return JSON.stringify(config, null, 2);
}

function indent(text: string): string {
  return text.split("\n").map((line) => `  ${line}`).join("\n");
}

function valueOrDash(value: string): string {
  return value.trim().length > 0 ? value : "-";
}

function formatDuration(durationMs: number): string {
  if (durationMs < 1000) return `${durationMs} ms`;
  return `${(durationMs / 1000).toFixed(2)} s`;
}

function statusLabel(status: NodeExecutionResult["status"]): string {
  return status === "executed" ? "ausgeführt" : "übersprungen";
}

function selectedTargetFor(result: NodeExecutionResult): string {
  if (result.selectedBranchLabel) {
    return `Gewählter Zweig: ${result.selectedBranchLabel}`;
  }
  if (result.selectedNodeId) return `Nächster Baustein: ${result.selectedNodeId}`;
  return "";
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

function stackLine(error: unknown): string {
  if (!(error instanceof Error) || !error.stack) return "";
  return `Stack: ${error.stack}`;
}
