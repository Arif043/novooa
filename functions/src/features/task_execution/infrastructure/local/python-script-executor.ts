import {nodeFailures} from "../../domain/entities/node-failures.js";
import {type NodeFailure} from "../../domain/entities/node-failure.js";
import {err, ok, type Result} from "neverthrow";
import {spawn} from "node:child_process";
import path from "node:path";
import {type ScriptExecutor} from "../../domain/executors/script-executor.js";
import {type ScriptExecutionRequest, type ScriptExecutionResult, type ScriptWorkspace} from "../../domain/entities/script-execution.js";
import {scriptResultFrom} from "./script-result.js";
import {scriptPythonSource} from "./script-python-runtime.js";

const timeoutMs = 5000;
const maxOutputBytes = 10 * 1024;

export function createPythonScriptExecutor(workspace?: ScriptWorkspace): ScriptExecutor {
  return {execute: (request) => executePythonScript(request, workspace)};
}

async function executePythonScript(
  request: ScriptExecutionRequest,
  workspace?: ScriptWorkspace,
): Promise<Result<ScriptExecutionResult, NodeFailure>> {
  const process = await runPython(request, workspace);
  if (process.code !== 0) {
    return err(nodeFailures.scriptFailed(process.stderr || "Script failed.", {stdout: "", stderr: process.stderr}));
  }
  if (Buffer.byteLength(process.stdout, "utf8") > maxOutputBytes) throw new Error("Script-Output ist zu groß.");
  return ok(scriptResultFrom(parseResponse(process.stdout)));
}

type PythonProcess = {code: number | null; stdout: string; stderr: string};

function runPython(request: ScriptExecutionRequest, workspace?: ScriptWorkspace): Promise<PythonProcess> {
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
    child.on("close", (code) => finish(timer, () => resolve({
      code, stdout: Buffer.concat(output).toString("utf8"), stderr: Buffer.concat(errors).toString("utf8"),
    })));
    child.stdin.end(JSON.stringify(payloadFor(request, workspace)));
  });
}

function pythonExecutable(): string {
  return process.env.PYTHON_EXECUTABLE?.trim() || "python3";
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

function finish(timer: NodeJS.Timeout, callback: () => void): void {
  clearTimeout(timer);
  callback();
}
