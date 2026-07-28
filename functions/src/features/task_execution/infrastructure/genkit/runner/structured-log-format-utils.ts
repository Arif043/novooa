import {type NodeExecutionResult} from "./task-definition.js";

export function preview(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > 160
    ? `${normalized.slice(0, 157)}...`
    : normalized;
}

export function formatConfig(config: unknown): string {
  return JSON.stringify(config, null, 2);
}

export function formatInline(value: unknown): string {
  return JSON.stringify(value) ?? String(value);
}

export function indent(text: string): string {
  return text.split("\n").map((line) => `  ${line}`).join("\n");
}

export function valueOrDash(value: string): string {
  return value.trim().length > 0 ? value : "-";
}

export function formatDuration(durationMs: number): string {
  if (durationMs < 1000) return `${durationMs} ms`;
  return `${(durationMs / 1000).toFixed(2)} s`;
}

export function statusLabel(status: NodeExecutionResult["status"]): string {
  return status === "executed" ? "ausgeführt" : "übersprungen";
}

export function selectedTargetFor(result: NodeExecutionResult): string {
  if (result.selectedBranchLabel) {
    return `Gewählter Zweig: ${result.selectedBranchLabel}`;
  }
  if (result.selectedNodeId) return `Nächster Baustein: ${result.selectedNodeId}`;
  return "";
}

export function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

export function stackLine(error: unknown): string {
  if (!(error instanceof Error) || !error.stack) return "";
  return `Stack: ${error.stack}`;
}
