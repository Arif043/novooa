import {spawn} from "node:child_process";
import {
  type NodeExecutor,
  executedNode,
  parentOutputFor,
} from "../task-runner/node-executor.js";
import { logInfo } from "../task-runner/structured-logger.js";

const timeoutMs = 5000;
const maxOutputBytes = 10 * 1024;
const pythonSource = `
import json
import sys

payload = json.loads(sys.stdin.read())
input = payload["input"]
printed = []

def safe_print(*values, sep=" ", end="\\n"):
    printed.append(sep.join(str(value) for value in values) + end)

safe_builtins = {
    "bool": bool,
    "dict": dict,
    "enumerate": enumerate,
    "float": float,
    "int": int,
    "len": len,
    "list": list,
    "max": max,
    "min": min,
    "print": safe_print,
    "range": range,
    "round": round,
    "set": set,
    "sorted": sorted,
    "str": str,
    "sum": sum,
    "tuple": tuple,
}

namespace = {"input": input}
exec(payload["script"], {"__builtins__": safe_builtins}, namespace)
output = namespace.get("output")

if output is None:
    output = "".join(printed)

if not isinstance(output, str):
    raise TypeError("Script muss eine String-Variable output setzen oder Text printen.")

sys.stdout.write(json.dumps({"output": output}))
`;

export const scriptNodeExecutor: NodeExecutor = {
  primitive: "script",
  async execute(input) {
    const output = await executeScriptNode({
      input: parentOutputFor(input.node, input.task, input.results),
      script: scriptFor(input.node),
    });
    logInfo("SDKLFj;JJKLSDfGJHNSdfKLGFJsdKLGSDfJSDFGKLFJSDKLFJSDKLFJSDKLJFSDjSDFKJ;SDLJkFHSDKJSDfHSJKSDFHnbj");
    console.info("Script Output: ", output);
    return executedNode(input.node, output);
  },
};

type ScriptNodeInput = {
  input: string;
  script: string;
};

export async function executeScriptNode(input: ScriptNodeInput): Promise<string> {
  const result = await runPython(input);
  const parsed = JSON.parse(result.stdout) as {output?: unknown};
  if (typeof parsed.output !== "string") {
    throw new Error("Script hat keinen String-Output geliefert.");
  }
  logInfo("Script Output: " + parsed.output);
  return parsed.output;
}

function runPython(input: ScriptNodeInput): Promise<{stdout: string}> {
  return new Promise((resolve, reject) => {
    const child = spawn("python3", ["-I", "-c", pythonSource], {
      stdio: ["pipe", "pipe", "pipe"],
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
    child.stdin.end(JSON.stringify(input));
  });
}

function finish(timer: NodeJS.Timeout, callback: () => void): void {
  clearTimeout(timer);
  callback();
}

function scriptFor(node: Parameters<NodeExecutor["execute"]>[0]["node"]): string {
  return node.config.primitive === "script" ? node.config.script : "";
}
