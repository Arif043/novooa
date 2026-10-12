import {isRecord, sidecarErrorMessage} from "./python-inference-sidecar-codec.js";

/** Wie sich die Runtime beim ML-Dienst ausweist; der zentrale Dienst eines Servers verlangt ein Token. */
export interface MlServiceCredentials {
  /** Wert für `Authorization`, oder `undefined`, wenn der Dienst keine Anmeldung kennt. */
  authorization(): Promise<string | undefined>;
  /** Nach `401` mit dieser Anmeldung: das Token ist ungültig geworden (z. B. vom Betreiber gelöscht) — neu anmelden. */
  renew(rejectedAuthorization: string): Promise<void>;
}

/** Für einen ML-Dienst ohne Mandanten (Cloud-Run-Pod). */
export const anonymousMlService: MlServiceCredentials = {
  authorization: () => Promise.resolve(undefined),
  renew: () => Promise.resolve(),
};

export type MlServiceRequest = {
  method: "POST" | "PUT" | "DELETE";
  path: string;
  headers?: Record<string, string>;
  /** Wird je Versuch neu erzeugt, damit sich auch ein Datenstrom erneut senden lässt. */
  body?: () => BodyInit;
};

export type MlServiceResponse = {status: number; payload: unknown};

/** JSON-Anfragen an den ML-Dienst, die bei einem Fehler dessen Meldung werfen. */
export interface MlServiceJsonClient {
  post(path: string, body: string): Promise<unknown>;
}

export type MlServiceRetryPolicy = {maximumWaitMs: number; initialDelayMs: number; maximumDelayMs: number};

const defaultRetryPolicy: MlServiceRetryPolicy = {maximumWaitMs: 120_000, initialDelayMs: 250, maximumDelayMs: 5_000};

/**
 * Der Zugang zum ML-Dienst: Anmeldung mitsenden, nach `401` einmal neu anmelden, bei `429`/`503` (ausgelastet)
 * mit wachsendem Abstand bzw. nach `Retry-After` erneut versuchen, bis die Höchstdauer erreicht ist.
 */
export class MlServiceHttp implements MlServiceJsonClient {
  constructor(
    private readonly baseUrl: string,
    private readonly credentials: MlServiceCredentials = anonymousMlService,
    private readonly retry: MlServiceRetryPolicy = defaultRetryPolicy,
    private readonly sleep: (ms: number) => Promise<void> = delay,
  ) {}

  async post(path: string, body: string): Promise<unknown> {
    const response = await this.send({method: "POST", path, headers: {"content-type": "application/json"}, body: () => body});
    if (response.status >= 400) throw new Error(sidecarErrorMessage(response.payload));
    return response.payload;
  }

  async send(request: MlServiceRequest): Promise<MlServiceResponse> {
    const deadline = Date.now() + this.retry.maximumWaitMs;
    let renewed = false;
    for (let attempt = 0; ; attempt += 1) {
      const authorization = await this.credentials.authorization();
      const response = await this.fetchOnce(request, authorization);
      if (response.status === 401 && authorization !== undefined && !renewed) {
        renewed = true;
        await response.body?.cancel();
        await this.credentials.renew(authorization);
        continue;
      }
      const wait = this.waitBeforeRetry(response, attempt);
      if (wait === undefined || Date.now() + wait > deadline) return {status: response.status, payload: await payloadOf(response)};
      await response.body?.cancel();
      await this.sleep(wait);
    }
  }

  private fetchOnce(request: MlServiceRequest, authorization: string | undefined): Promise<Response> {
    return fetch(new URL(request.path, this.baseUrl), {
      method: request.method,
      headers: {...request.headers, ...(authorization === undefined ? {} : {authorization})},
      body: request.body?.(),
      duplex: "half",
    } as RequestInit & {duplex: "half"});
  }

  private waitBeforeRetry(response: Response, attempt: number): number | undefined {
    if (response.status !== 429 && response.status !== 503) return undefined;
    const retryAfter = Number(response.headers.get("retry-after"));
    const backoff = Math.min(this.retry.initialDelayMs * 2 ** attempt, this.retry.maximumDelayMs);
    return Number.isFinite(retryAfter) && retryAfter > 0 ? Math.max(retryAfter * 1000, backoff) : backoff;
  }
}

async function payloadOf(response: Response): Promise<unknown> {
  const text = await response.text();
  if (text.length === 0) return {};
  try {
    return JSON.parse(text) as unknown;
  } catch {
    return {error: text};
  }
}

export function responseCode(response: MlServiceResponse): string | undefined {
  return isRecord(response.payload) && typeof response.payload.code === "string" ? response.payload.code : undefined;
}

function delay(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
