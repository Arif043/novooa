import {type NodeExecutionResult} from "./task-definition.js";

export function preview(text: string): string {
  const normalized = text.replace(/\s+/g, " ").trim();
  return normalized.length > 160
    ? `${normalized.slice(0, 157)}...`
    : normalized;
}

export function formatConfig(config: unknown): string {
  return JSON.stringify(redactedConfig(config), null, 2);
}

const maskedValue = "•••";
const sensitiveName = /(authorization|api[-_]?key|token|secret|passw|signature|cookie|auth)/i;
const sensitiveQueryParameter = /([?&][^=&#]*(?:authorization|api[-_]?key|token|secret|passw|signature|auth)[^=&#]*=)[^&#]*/gi;

/**
 * Was ins Aktivitätslog darf: Bei HTTP-Anfragen stehen Geheimnisse oft in Headern, Query-Werten oder dem Body
 * (selbst eingetippt, nicht aus einer Verbindung). Header-Werte und der Body werden deshalb nie geloggt,
 * Query-Werte nur, wenn ihr Name nicht nach Zugangsdaten klingt. Andere Bausteine bleiben unverändert.
 */
export function redactedConfig(config: unknown): unknown {
  if (typeof config !== "object" || config === null || (config as {primitive?: unknown}).primitive !== "httpRequest") return config;
  const http = config as {headers?: unknown; query?: unknown; url?: unknown; body?: unknown};
  const mask = (pairs: unknown, always: boolean) => Array.isArray(pairs)
    ? pairs.map((pair: {name?: unknown; value?: unknown}) => ({
      ...pair, value: always || (typeof pair.name === "string" && sensitiveName.test(pair.name)) ? maskedValue : pair.value,
    }))
    : pairs;
  return {
    ...config,
    url: typeof http.url === "string" ? http.url.replace(sensitiveQueryParameter, `$1${maskedValue}`) : http.url,
    headers: mask(http.headers, true),
    query: mask(http.query, false),
    body: typeof http.body === "string" && http.body !== "" ? `${maskedValue} (${http.body.length} Zeichen)` : http.body,
  };
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
