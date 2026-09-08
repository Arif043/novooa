import {
  createServer,
  type IncomingMessage,
  type Server,
  type ServerResponse,
} from "node:http";

export type LocalRuntimeRequest = {
  body: unknown;
  method?: string;
  url?: string;
};

export type LocalRuntimeResponse = {
  body: object;
  statusCode: number;
};

export interface LocalRuntimeRequestHandler {
  handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null>;
}

export function createLocalRuntimeHttpServer(
  handler?: LocalRuntimeRequestHandler,
): Server {
  return createServer((request, response) => void respondTo(request, response, handler));
}

async function respondTo(
  request: IncomingMessage,
  response: ServerResponse,
  handler: LocalRuntimeRequestHandler | undefined,
): Promise<void> {
  const localResponse = await responseFor(request, handler).catch(errorResponseFor);
  respondJson(response, localResponse.statusCode, localResponse.body);
}

async function responseFor(
  request: IncomingMessage,
  handler: LocalRuntimeRequestHandler | undefined,
): Promise<LocalRuntimeResponse> {
  const body = await requestBody(request);
  return localRuntimeResponseFor({...request, body}, handler);
}

export async function localRuntimeResponseFor(
  request: LocalRuntimeRequest,
  handler?: LocalRuntimeRequestHandler,
): Promise<LocalRuntimeResponse> {
  if (request.method === "GET" && request.url === "/healthz") {
    return {body: {status: "ok"}, statusCode: 200};
  }
  const handled = await handler?.handle(request);
  if (handled !== undefined && handled !== null) return handled;
  return {body: {error: "Endpunkt nicht gefunden."}, statusCode: 404};
}

function respondJson(response: ServerResponse, statusCode: number, body: object): void {
  response.writeHead(statusCode, {"content-type": "application/json; charset=utf-8"});
  response.end(JSON.stringify(body));
}

async function requestBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of request) {
    const buffer = Buffer.from(chunk);
    size += buffer.length;
    if (size > 75 * 1024 * 1024) throw new InvalidLocalRuntimeRequestError();
    chunks.push(buffer);
  }
  const value = Buffer.concat(chunks).toString("utf8").trim();
  if (value.length === 0) return {};
  try {
    return JSON.parse(value) as unknown;
  } catch {
    throw new InvalidLocalRuntimeRequestError();
  }
}

function errorResponseFor(error: unknown): LocalRuntimeResponse {
  if (error instanceof InvalidLocalRuntimeRequestError) return invalidRequestResponse();
  console.error(JSON.stringify({event: "local_runtime.http_failed", error: errorMessage(error)}));
  return {body: {error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."}, statusCode: 500};
}

function invalidRequestResponse(): LocalRuntimeResponse {
  return {body: {error: "Ungültige lokale Anfrage."}, statusCode: 400};
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

class InvalidLocalRuntimeRequestError extends Error {}
