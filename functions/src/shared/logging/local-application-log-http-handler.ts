import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "../local/local-runtime-http-server.js";
import {type LocalApplicationLogStore} from "./local-application-log-store.js";

export class LocalApplicationLogHttpHandler implements LocalRuntimeRequestHandler {
  constructor(
    private readonly store: LocalApplicationLogStore,
    private readonly teamId: string,
  ) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (!isApplicationLogRequest(request)) return null;
    const logs = await this.store.recent(this.teamId, 100);
    return {body: {items: logs.map(documentFrom)}, statusCode: 200};
  }
}

function isApplicationLogRequest(request: LocalRuntimeRequest): boolean {
  const path = new URL(request.url ?? "/", "http://local-runtime").pathname;
  return request.method === "GET" && path === "/v1/application-logs";
}

function documentFrom(log: {
  id: string;
  level: string;
  event: string;
  message: string | null;
  data: Record<string, unknown>;
  occurredAt: string;
}): Record<string, unknown> {
  return {
    id: log.id,
    level: log.level,
    event: log.event,
    message: log.message,
    data: log.data,
    occurredAt: log.occurredAt,
  };
}
