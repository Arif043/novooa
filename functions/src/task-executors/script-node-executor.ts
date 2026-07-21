import {spawn} from "node:child_process";
import path from "node:path";
import {
  type NodeExecutor,
  type TaskVariables,
  executedNode,
  parentOutputFor,
  textOutputs,
} from "../task-runner/node-executor.js";
import {
  logInfo,
  logReadableInfo,
} from "../task-runner/structured-logger.js";
import {
  type NodeAttachmentWorkspace,
  type PreparedNodeAttachment,
} from "../task-runner/node-attachment-workspace.js";
import {scriptPythonSource} from "./script-python-runtime.js";

const timeoutMs = 5000;
const maxOutputBytes = 10 * 1024;

export const scriptNodeExecutor: NodeExecutor = {
  primitive: "script",
  async execute(input, runContext) {
    const parentOutput = parentOutputFor(
      input.node,
      runContext.task,
      runContext.results,
    );
    const output = await executeScriptNode({
      input: runContext.resolveTemplates(parentOutput),
      script: runContext.resolveTemplates(scriptFor(input.node)),
      variables: runContext.variables,
      attachmentWorkspace: input.attachmentWorkspace,
    });
    return executedNode(input.node, textOutputs(output.output), {
      variables: output.variables,
    });
  },
};

type ScriptNodeInput = {
  input: string;
  script: string;
  variables: TaskVariables;
  attachmentWorkspace?: NodeAttachmentWorkspace;
};

type ScriptNodeOutput = {
  output: string;
  variables: TaskVariables;
};

export async function executeScriptNode(
  input: ScriptNodeInput,
): Promise<ScriptNodeOutput> {
  const result = await runPython(input);
  const parsed = JSON.parse(result.stdout) as {
    output?: unknown;
    printed?: unknown;
    variables?: unknown;
  };
  if (typeof parsed.output !== "string") {
    throw new Error("Script hat keinen String-Output geliefert.");
  }
  if (typeof parsed.printed === "string") logScriptPrints(parsed.printed);
  return {
    output: parsed.output,
    variables: variablesFrom(parsed.variables),
  };
}

function runPython(input: ScriptNodeInput): Promise<{stdout: string}> {
  return new Promise((resolve, reject) => {
    const payload = scriptPayload(input);
    const child = spawn("python3", ["-I", "-c", scriptPythonSource], {
      stdio: ["pipe", "pipe", "pipe"],
      cwd: input.attachmentWorkspace?.rootDirectory,
    });
    const timer = setTimeout(() => {
      child.kill("SIGKILL");
      reject(new Error("Script-Timeout überschritten."));
    }, timeoutMs);
    const chunks: Buffer[] = [];
    const errors: Buffer[] = [];
    child.stdout.on("data", (chunk: Buffer) => chunks.push(chunk));
    child.stderr.on("data", (chunk: Buffer) => errors.push(chunk));
    child.on("error", (error) => finish(timer, () => reject(error)));
    child.on("close", (code) => finish(timer, () => {
      const stdout = Buffer.concat(chunks).toString("utf8");
      const stderr = Buffer.concat(errors).toString("utf8");
      if (code !== 0) return reject(new Error(stderr || "Script fehlgeschlagen."));
      if (Buffer.byteLength(stdout, "utf8") > maxOutputBytes) {
        return reject(new Error("Script-Output ist zu groß."));
      }
      return resolve({stdout});
    }));
    child.stdin.end(JSON.stringify(payload));
  });
}

function scriptPayload(input: ScriptNodeInput) {
  return {
    input: input.input,
    script: input.script,
    variables: input.variables,
    files: scriptFiles(input.attachmentWorkspace),
  };
}

function scriptFiles(workspace?: NodeAttachmentWorkspace) {
  if (!workspace) return [];
  return workspace.files.map((file) => scriptFile(workspace.rootDirectory, file));
}

function scriptFile(rootDirectory: string, file: PreparedNodeAttachment) {
  return {
    displayName: file.displayName,
    contentType: file.contentType,
    sizeBytes: file.sizeBytes,
    path: path.join(rootDirectory, file.filename),
  };
}

function finish(timer: NodeJS.Timeout, callback: () => void): void {
  clearTimeout(timer);
  callback();
}

function variablesFrom(value: unknown): TaskVariables {
  if (value === null || typeof value !== "object" || Array.isArray(value)) {
    return {};
  }
  return value as TaskVariables;
}

function logScriptPrints(printed: string): void {
  if (printed.trim().length === 0) return;
  logReadableInfo(["[Script-Log]", printed.trimEnd()].join("\n"));
  logInfo("script_node.printed", {
    length: printed.length,
    preview: printed.slice(0, 1000),
  });
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
