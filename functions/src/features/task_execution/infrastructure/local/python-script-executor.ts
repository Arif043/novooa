import {spawn} from "node:child_process";
import path from "node:path";
import {type ScriptExecutor} from "../../domain/executors/script-executor.js";
import {type ScriptExecutionRequest, type ScriptExecutionResult} from "../../domain/entities/script-execution.js";
import {scriptPythonSource} from "./script-python-runtime.js";

const timeoutMs = 5000;
const maxOutputBytes = 10 * 1024;

type ScriptWorkspace = {
  rootDirectory: string;
  files: readonly ScriptWorkspaceFile[];
};

type ScriptWorkspaceFile = {
  displayName: string;
  contentType: string;
  sizeBytes: number;
  versionCreatedAt?: number;
  filename: string;
};

export function createPythonScriptExecutor(workspace?: ScriptWorkspace): ScriptExecutor {
  return {execute: (request) => executePythonScript(request, workspace)};
}

async function executePythonScript(
  request: ScriptExecutionRequest,
  workspace?: ScriptWorkspace,
): Promise<ScriptExecutionResult> {
  const parsed = parseResponse(await runPython(request, workspace));
  return {
    output: outputFrom(parsed, request.input),
    variables: variablesFrom(parsed.variables),
    printed: typeof parsed.printed === "string" ? parsed.printed : "",
  };
}

function runPython(request: ScriptExecutionRequest, workspace?: ScriptWorkspace): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(pythonExecutable(), ["-I", "-c", scriptPythonSource], {
      stdio: ["pipe", "pipe", "pipe"], cwd: workspace?.rootDirectory,
    });
    const timer = setTimeout(() => { child.kill("SIGKILL"); reject(new Error("Script-Timeout überschritten.")); }, timeoutMs);
    const output: Buffer[] = [];
    const errors: Buffer[] = [];
    child.stdout.on("data", (chunk: Buffer) => output.push(chunk));
    child.stderr.on("data", (chunk: Buffer) => errors.push(chunk));
    child.on("error", (error) => finish(timer, () => reject(error)));
    child.on("close", (code) => finish(timer, () => completeProcess(code, output, errors, resolve, reject)));
    child.stdin.end(JSON.stringify(payloadFor(request, workspace)));
  });
}

function pythonExecutable(): string {
  return process.env.PYTHON_EXECUTABLE?.trim() || "python3";
}

function completeProcess(
  code: number | null,
  output: Buffer[],
  errors: Buffer[],
  resolve: (value: string) => void,
  reject: (reason: Error) => void,
): void {
  const stdout = Buffer.concat(output).toString("utf8");
  const stderr = Buffer.concat(errors).toString("utf8");
  if (code !== 0) return reject(new Error(stderr || "Script fehlgeschlagen."));
  if (Buffer.byteLength(stdout, "utf8") > maxOutputBytes) return reject(new Error("Script-Output ist zu groß."));
  resolve(stdout);
}

function payloadFor(request: ScriptExecutionRequest, workspace?: ScriptWorkspace) {
  return {...request, files: workspace?.files.map((file) => ({
    displayName: file.displayName, contentType: file.contentType, sizeBytes: file.sizeBytes,
    versionCreatedAt: file.versionCreatedAt, path: path.join(workspace.rootDirectory, file.filename),
  })) ?? []};
}

function parseResponse(value: string): Record<string, unknown> {
  const parsed = JSON.parse(value) as unknown;
  if (parsed === null || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Script lieferte eine ungültige Antwort.");
  }
  return parsed as Record<string, unknown>;
}

function outputFrom(parsed: Record<string, unknown>, fallback: string): string {
  if (parsed.outputDefined === false) return fallback;
  if (typeof parsed.output === "string") return parsed.output;
  throw new Error("Script hat keinen String-Output geliefert.");
}

function variablesFrom(value: unknown): Record<string, unknown> {
  return value !== null && typeof value === "object" && !Array.isArray(value)
    ? value as Record<string, unknown> : {};
}

function finish(timer: NodeJS.Timeout, callback: () => void): void {
  clearTimeout(timer);
  callback();
}
