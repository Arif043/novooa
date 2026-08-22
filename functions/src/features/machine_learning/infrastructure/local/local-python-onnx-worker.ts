import {spawn} from "node:child_process";
import {type PythonOnnxWorker, type PythonOnnxWorkerRequest} from "./python-onnx-worker.js";
import {
  pythonOnnxWorkerInputJson,
  pythonOnnxWorkerOutputFromJson,
} from "./python-onnx-worker-codec.js";

const defaultTimeoutMs = 60000;
const maxOutputBytes = 64 * 1024 * 1024;

export type LocalPythonOnnxWorkerOptions = {
  pythonExecutable: string;
  workerScriptPath: string;
  timeoutMs?: number;
};

export class LocalPythonOnnxWorker implements PythonOnnxWorker {
  constructor(private readonly options: LocalPythonOnnxWorkerOptions) {}

  async execute(request: PythonOnnxWorkerRequest) {
    const stdout = await runPython(this.options, pythonOnnxWorkerInputJson(request));
    return pythonOnnxWorkerOutputFromJson(stdout);
  }
}

function runPython(options: LocalPythonOnnxWorkerOptions, payload: string): Promise<string> {
  return new Promise((resolve, reject) => {
    const child = spawn(options.pythonExecutable, ["-I", options.workerScriptPath], {
      stdio: ["pipe", "pipe", "pipe"],
    });
    new PythonProcessObserver(child, resolve, reject, options.timeoutMs ?? defaultTimeoutMs);
    child.stdin.end(payload);
  });
}

class PythonProcessObserver {
  private readonly stdout: Buffer[] = [];
  private readonly stderr: Buffer[] = [];
  private readonly timeout: NodeJS.Timeout;
  private outputBytes = 0;
  private settled = false;

  constructor(
    private readonly child: ReturnType<typeof spawn>,
    private readonly resolve: (value: string) => void,
    private readonly reject: (reason: Error) => void,
    timeoutMs: number,
  ) {
    this.timeout = setTimeout(() => this.timedOut(), timeoutMs);
    requiredStream(child.stdout, "Standardausgabe").on("data", (chunk: Buffer) => this.collectStdout(chunk));
    requiredStream(child.stderr, "Fehlerausgabe").on("data", (chunk: Buffer) => this.stderr.push(chunk));
    child.on("error", (error: Error) => this.failed(error));
    child.on("close", (code) => this.closed(code));
  }

  private collectStdout(chunk: Buffer): void {
    this.outputBytes += chunk.byteLength;
    if (this.outputBytes > maxOutputBytes) return this.failed(new Error("Die ONNX-Ausgabe ist zu groß."));
    this.stdout.push(chunk);
  }

  private timedOut(): void {
    this.child.kill("SIGKILL");
    this.failed(new Error("Die lokale ONNX-Inferenz hat das Zeitlimit überschritten."));
  }

  private closed(code: number | null): void {
    if (code === 0) return this.succeeded(Buffer.concat(this.stdout).toString("utf8"));
    this.failed(new Error(processError(this.stdout, this.stderr)));
  }

  private succeeded(value: string): void {
    if (this.settled) return;
    this.settled = true;
    clearTimeout(this.timeout);
    this.resolve(value);
  }

  private failed(error: Error): void {
    if (this.settled) return;
    this.settled = true;
    clearTimeout(this.timeout);
    this.reject(error);
  }
}

function processError(stdout: readonly Buffer[], stderr: readonly Buffer[]): string {
  const message = Buffer.concat(stderr).toString("utf8").trim();
  if (message.length > 0) return message;
  const response = Buffer.concat(stdout).toString("utf8").trim();
  return response || "Die lokale ONNX-Runtime ist fehlgeschlagen.";
}

function requiredStream<T>(stream: T | null, name: string): T {
  if (stream === null) throw new Error(`Die Python-${name} ist nicht verfügbar.`);
  return stream;
}
