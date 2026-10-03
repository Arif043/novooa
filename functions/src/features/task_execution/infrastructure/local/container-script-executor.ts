import {readFile} from "node:fs/promises";
import path from "node:path";
import {type ScriptExecutionRequest, type ScriptExecutionResult, type ScriptWorkspace} from "../../domain/entities/script-execution.js";
import {type ScriptExecutorFactory} from "../../domain/executors/script-executor.js";
import {scriptResultFrom} from "./script-result.js";

/** Obergrenze für alle angehängten Dateien eines Laufs; größere gehören nicht in ein Script. */
export const maximumAttachmentBytes = 25 * 1024 * 1024;

const requestTimeoutMs = 20_000;

/**
 * Führt Scripts im abgeschotteten Python-Container (`novooa-script`) aus. Die
 * angehängten Dateien gehen als rohe Bytes im Multipart mit, ohne Kodierung.
 */
export function createContainerScriptExecutorFactory(endpoint: string): ScriptExecutorFactory {
  const url = new URL("/run", endpoint);
  return (workspace) => ({execute: (request) => executeInContainer(url, request, workspace)});
}

/** Ohne Adresse des Dienstes läuft kein Script — nie ungeschützt in der Runtime selbst. */
export function unavailableScriptExecutorFactory(): ScriptExecutorFactory {
  return () => ({
    execute: async () => {
      throw new Error("Der Script-Dienst ist nicht konfiguriert (SCRIPT_RUNNER_URL).");
    },
  });
}

async function executeInContainer(
  url: URL,
  request: ScriptExecutionRequest,
  workspace?: ScriptWorkspace,
): Promise<ScriptExecutionResult> {
  const files = workspace?.files ?? [];
  assertWithinLimit(files);
  const body = new FormData();
  body.append("request", new Blob([JSON.stringify(requestBody(request, files))], {type: "application/json"}), "request.json");
  for (const [index, file] of files.entries()) {
    const bytes = await readFile(path.join(workspace!.rootDirectory, file.filename));
    body.append(`file-${index}`, new Blob([bytes], {type: file.contentType}), `file-${index}`);
  }
  return scriptResultFrom(await post(url, body), request.input);
}

function requestBody(request: ScriptExecutionRequest, files: ScriptWorkspace["files"]) {
  return {
    script: request.script, input: request.input, variables: request.variables,
    files: files.map(({displayName, contentType, sizeBytes, versionCreatedAt}) => ({
      displayName, contentType, sizeBytes, versionCreatedAt,
    })),
  };
}

function assertWithinLimit(files: ScriptWorkspace["files"]): void {
  const total = files.reduce((sum, file) => sum + file.sizeBytes, 0);
  if (total > maximumAttachmentBytes) {
    throw new Error("Die angehängten Dateien sind zusammen größer als 25 MB. Hänge weniger oder kleinere Dateien an.");
  }
}

async function post(url: URL, body: FormData): Promise<Record<string, unknown>> {
  let response: Response;
  try {
    response = await fetch(url, {method: "POST", body, signal: AbortSignal.timeout(requestTimeoutMs)});
  } catch {
    throw new Error("Der Script-Dienst ist nicht erreichbar.");
  }
  const parsed = await response.json().catch(() => ({})) as Record<string, unknown>;
  if (!response.ok) {
    throw new Error(typeof parsed.error === "string" ? parsed.error : "Der Script-Dienst hat die Anfrage abgelehnt.");
  }
  return parsed;
}
