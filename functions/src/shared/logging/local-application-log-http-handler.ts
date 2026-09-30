import { type FastifyInstance, type FastifyReply } from "fastify";
import { randomUUID } from "node:crypto";
import { type ApplicationLogLevel, type LocalApplicationLogStore, } from "./local-application-log-store.js";
import { type LocalRuntimeRealtimeNotifier } from "../local/local-runtime-realtime-notifier.js";
export class LocalApplicationLogHttpHandler {
  static registerRoutes(http: FastifyInstance, current: () => LocalApplicationLogHttpHandler): void {
    http.get("/v1/application-logs", (request, reply) => current().recent(reply));
    http.post("/v1/application-logs", (request, reply) => current().append(request.body, reply));
  }
  constructor(private readonly store: LocalApplicationLogStore, private readonly teamId: string, private readonly notifier: LocalRuntimeRealtimeNotifier) { }
  private async recent(reply: FastifyReply): Promise<FastifyReply> {
    const logs = await this.store.recent(this.teamId, 100);
    return reply.code(200).send({ items: logs.map(documentFrom) });
  }
  private async append(body: unknown, reply: FastifyReply): Promise<FastifyReply> {
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
      this.notifier.publish("application-logs");
      return reply.code(202).send({});
    }
    catch (error) {
      if (error instanceof LocalApplicationLogRequestError) {
        return reply.code(400).send({ error: error.message });
      }
      throw error;
    }
  }
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
  if (JSON.stringify(data).length > 16000)
    throw invalid("Die Protokolldaten sind zu groß.");
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
  if (value === "info" || value === "error")
    return value;
  throw invalid("Die Protokollstufe ist ungültig.");
}
function eventFrom(value: unknown): string {
  if (typeof value === "string" && /^[a-z0-9._-]{1,120}$/.test(value))
    return value;
  throw invalid("Das Protokollereignis ist ungültig.");
}
function optionalMessage(value: unknown): string | null {
  if (value === null || value === undefined)
    return null;
  if (typeof value === "string" && value.length <= 4000)
    return value;
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
class LocalApplicationLogRequestError extends Error {
}
