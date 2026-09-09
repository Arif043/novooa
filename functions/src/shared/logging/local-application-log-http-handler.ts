import {randomUUID} from "node:crypto";
import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../local/local-runtime-http-server.js";
import {
  type ApplicationLogLevel,
  type LocalApplicationLogStore,
} from "./local-application-log-store.js";

export class LocalApplicationLogHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly store: LocalApplicationLogStore,
    private readonly teamId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (isReadRequest(request)) return this.recent();
    if (isWriteRequest(request)) return this.append(request.body);
    return null;
  }

  private async recent(): Promise<LocalRuntimeResponse> {
    const logs = await this.store.recent(this.teamId, 100);
    return {body: {items: logs.map(documentFrom)}, statusCode: 200};
  }

  private async append(body: unknown): Promise<LocalRuntimeResponse> {
    try {
      const input = clientLogFrom(body);
      await this.store.append({
        id: randomUUID(),
        teamId: this.teamId,
        source: "client",
        level: input.level,
        event: input.event,
        message: input.message,
        data: input.data,
        occurredAt: new Date().toISOString(),
      });
      return {body: {}, statusCode: 202};
    } catch (error) {
      if (error instanceof LocalApplicationLogRequestError) {
        return {body: {error: error.message}, statusCode: 400};
      }
      throw error;
    }
  }
}

function isReadRequest(request: LocalRuntimeRequest): boolean {
  const path = new URL(request.url ?? "/", "http://local-runtime").pathname;
  return request.method === "GET" && path === "/v1/application-logs";
}

function isWriteRequest(request: LocalRuntimeRequest): boolean {
  const path = new URL(request.url ?? "/", "http://local-runtime").pathname;
  return request.method === "POST" && path === "/v1/application-logs";
}

function documentFrom(log: {
  id: string;
  level: string;
  source: string;
  event: string;
  message: string | null;
  data: Record<string, unknown>;
  occurredAt: string;
}): Record<string, unknown> {
  return {
    id: log.id,
    source: log.source,
    level: log.level,
    event: log.event,
    message: log.message,
    data: log.data,
    occurredAt: log.occurredAt,
  };
}

function clientLogFrom(value: unknown): ClientLogInput {
  const input = recordFrom(value);
  const data = recordFrom(input.data ?? {});
  if (JSON.stringify(data).length > 16_000) throw invalid("Die Protokolldaten sind zu groß.");
  return {
    level: levelFrom(input.level),
    event: eventFrom(input.event),
    message: optionalMessage(input.message),
    data,
  };
}

function recordFrom(value: unknown): Record<string, unknown> {
  if (value !== null && typeof value === "object" && !Array.isArray(value)) {
    return value as Record<string, unknown>;
  }
  throw invalid("Der Protokolleintrag ist ungültig.");
}

function levelFrom(value: unknown): ApplicationLogLevel {
  if (value === "info" || value === "error") return value;
  throw invalid("Die Protokollstufe ist ungültig.");
}

function eventFrom(value: unknown): string {
  if (typeof value === "string" && /^[a-z0-9._-]{1,120}$/.test(value)) return value;
  throw invalid("Das Protokollereignis ist ungültig.");
}

function optionalMessage(value: unknown): string | null {
  if (value === null || value === undefined) return null;
  if (typeof value === "string" && value.length <= 4_000) return value;
  throw invalid("Die Protokollnachricht ist ungültig.");
}

function invalid(message: string): LocalApplicationLogRequestError {
  return new LocalApplicationLogRequestError(message);
}

type ClientLogInput = {
  data: Record<string, unknown>;
  event: string;
  level: ApplicationLogLevel;
  message: string | null;
};

class LocalApplicationLogRequestError extends Error {}
