import express, {
  type NextFunction,
  type Request,
  type Response,
} from "express";

const defaultTargets = [
  "http://127.0.0.1:3100/api/runAction",
  "http://127.0.0.1:3101/api/runAction",
];
const actionKey = "/flow/runTaskDefinitionFlow";
const port = Number(process.env.SYSCAT_GENKIT_PROXY_PORT ?? "3400");

type ReflectionEnvelope = {
  result?: unknown;
  error?: unknown;
};

const app = express();
app.use(express.json({limit: "1mb"}));
app.use(corsHeaders);

app.options("/runTaskDefinitionFlow", (_request, response) => {
  response.status(204).send();
});

app.post("/runTaskDefinitionFlow", async (request, response) => {
  try {
    const executionResult = await runViaReflection(request.body);
    if (executionResult.ok) {
      response.status(200).json(executionResult.result);
      return;
    }
    response.status(executionResult.status).json({message: executionResult.message});
  } catch (error) {
    logException("Proxy request failed.", error);
    response.status(500).json({message: "Genkit-Proxy ist fehlgeschlagen."});
  }
});

app.listen(port, "127.0.0.1", () => {
  console.info(`Genkit CORS proxy listening on http://127.0.0.1:${port}`);
});

function corsHeaders(
  request: Request,
  response: Response,
  next: NextFunction,
): void {
  const origin = typeof request.headers.origin === "string"
    ? request.headers.origin
    : "*";
  response.setHeader("Access-Control-Allow-Origin", origin);
  response.setHeader("Access-Control-Allow-Methods", "POST, OPTIONS");
  response.setHeader("Access-Control-Allow-Headers", "content-type");
  next();
}

async function runViaReflection(input: unknown): Promise<RunResult> {
  let lastFailure: RunResult = {
    ok: false,
    status: 503,
    message: "Genkit Dev Server nicht erreichbar.",
  };
  for (const target of reflectionTargets()) {
    const result = await tryRun(target, input);
    if (result.ok) return result;
    lastFailure = result;
    if (result.status !== 503) return result;
  }
  return lastFailure;
}

async function tryRun(target: string, input: unknown): Promise<RunResult> {
  try {
    const response = await fetch(target, {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({key: actionKey, input}),
    });
    if (!response.ok) {
      logException("Genkit reflection returned non-OK status.", {
        target,
        status: response.status,
        body: await response.text(),
      });
      return targetFailure(response.status);
    }
    return parseReflectionResponse(await response.json());
  } catch (error) {
    logException("Genkit reflection request failed.", {target, error});
    return {
      ok: false,
      status: 503,
      message: "Genkit Dev Server nicht erreichbar.",
    };
  }
}

function parseReflectionResponse(payload: unknown): RunResult {
  if (!isRecord(payload)) {
    return {ok: false, status: 502, message: "Ungueltige Genkit-Antwort."};
  }
  const envelope = payload as ReflectionEnvelope;
  if (envelope.error !== undefined) {
    logException("Genkit flow returned an error.", envelope.error);
    return {ok: false, status: 502, message: "Genkit-Ausfuehrung fehlgeschlagen."};
  }
  if (!isRecord(envelope.result)) {
    return {ok: false, status: 502, message: "Ungueltiges Flow-Ergebnis."};
  }
  return {ok: true, result: envelope.result};
}

function reflectionTargets(): string[] {
  const configuredTarget = process.env.GENKIT_REFLECTION_URL;
  return configuredTarget === undefined ? defaultTargets : [configuredTarget];
}

function targetFailure(status: number): RunResult {
  if (status === 404) {
    return {ok: false, status: 503, message: "Flow nicht gefunden."};
  }
  return {ok: false, status: 502, message: "Genkit-Ausfuehrung fehlgeschlagen."};
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function logException(message: string, error: unknown): void {
  console.error(`[Fehler] ${message}`);
  console.error(error);
}

type RunResult =
  | {ok: true; result: Record<string, unknown>}
  | {ok: false; status: number; message: string};
