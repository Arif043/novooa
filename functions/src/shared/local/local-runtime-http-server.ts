import {
  createServer,
  type IncomingMessage,
  type Server,
  type ServerResponse,
} from "node:http";
import {
  type LocalRuntimeStaticFile,
  type LocalRuntimeStaticFiles,
} from "./local-runtime-static-files.js";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";

export type LocalRuntimeRequest = {
  body: unknown;
  method?: string;
  url?: string;
  remoteAddress?: string;
  headers?: Readonly<Record<string, string | readonly string[] | undefined>>;
};

export type LocalRuntimeResponse = {
  body: object;
  statusCode: number;
};

export type LocalRuntimeStreamRequest = {
  body: AsyncIterable<Uint8Array>;
  headers: Readonly<Record<string, string | readonly string[] | undefined>>;
  method?: string;
  url?: string;
};

export interface LocalRuntimeRequestHandler {
  handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null>;
}

export interface LocalRuntimeStreamRequestHandler {
  handleStream(request: LocalRuntimeStreamRequest): Promise<LocalRuntimeResponse | null>;
}

export function createLocalRuntimeHttpServer(
  handler?: LocalRuntimeRequestHandler,
  staticFiles?: LocalRuntimeStaticFiles,
  cors: LocalRuntimeCorsPolicy = new LocalRuntimeCorsPolicy(),
): Server {
  return createServer(
    (request, response) => void respondTo(request, response, handler, staticFiles, cors),
  );
}

function headerValue(
  headers: IncomingMessage["headers"],
  name: "origin" | "host",
): string | undefined {
  const value = headers[name];
  return Array.isArray(value) ? value[0] : value;
}

/**
 * Statische Dateien werden erst geprüft, wenn **kein** Handler zuständig
 * war — ein Endpunkt lässt sich dadurch nicht versehentlich von einer Datei
 * überschatten. Sie liegen bewusst außerhalb der Lizenz- und Session-Gates,
 * damit die App vor Aktivierung und Anmeldung laden kann.
 */
async function respondTo(
  request: IncomingMessage,
  response: ServerResponse,
  handler: LocalRuntimeRequestHandler | undefined,
  staticFiles: LocalRuntimeStaticFiles | undefined,
  cors: LocalRuntimeCorsPolicy,
): Promise<void> {
  const origin = headerValue(request.headers, "origin");
  const corsHeaders = cors.headersFor(origin) ?? {};
  if (request.method === "OPTIONS") {
    response.writeHead(204, corsHeaders);
    response.end();
    return;
  }
  if (!cors.allows(origin, headerValue(request.headers, "host"))) {
    respondJson(response, 403, {error: "Herkunft nicht erlaubt."}, corsHeaders);
    return;
  }
  try {
    const handled = await handledResponseFor(request, handler);
    if (handled !== null) {
      respondJson(response, handled.statusCode, handled.body, corsHeaders);
      return;
    }
    const file = await staticFiles?.find(request.method ?? "GET", request.url ?? "/");
    if (file) {
      respondFile(response, file, corsHeaders);
      return;
    }
    respondJson(response, 404, notFoundBody, corsHeaders);
  } catch (error) {
    const failure = errorResponseFor(error);
    respondJson(response, failure.statusCode, failure.body, corsHeaders);
  }
}

/** `null`, wenn nichts zuständig war — dann kommen statische Dateien dran. */
async function handledResponseFor(
  request: IncomingMessage,
  handler: LocalRuntimeRequestHandler | undefined,
): Promise<LocalRuntimeResponse | null> {
  const streamed = await streamedResponseFor(request, handler);
  if (streamed !== null) return streamed;
  const body = await requestBody(request);
  return handledLocalRuntimeResponseFor({
    method: request.method,
    url: request.url,
    remoteAddress: request.socket.remoteAddress,
    headers: request.headers,
    body,
  }, handler);
}

async function handledLocalRuntimeResponseFor(
  request: LocalRuntimeRequest,
  handler?: LocalRuntimeRequestHandler,
): Promise<LocalRuntimeResponse | null> {
  if (request.method === "GET" && request.url === "/healthz") {
    return {body: {status: "ok"}, statusCode: 200};
  }
  return await handler?.handle(request) ?? null;
}

export async function localRuntimeResponseFor(
  request: LocalRuntimeRequest,
  handler?: LocalRuntimeRequestHandler,
): Promise<LocalRuntimeResponse> {
  const handled = await handledLocalRuntimeResponseFor(request, handler);
  return handled ?? {body: notFoundBody, statusCode: 404};
}

const notFoundBody = {error: "Endpunkt nicht gefunden."};

function respondFile(
  response: ServerResponse,
  file: LocalRuntimeStaticFile,
  extraHeaders: Record<string, string> = {},
): void {
  response.writeHead(200, {
    "content-type": file.contentType,
    "content-length": file.bytes.byteLength,
    ...extraHeaders,
  });
  response.end(file.bytes);
}

function respondJson(
  response: ServerResponse,
  statusCode: number,
  body: object,
  extraHeaders: Record<string, string> = {},
): void {
  response.writeHead(statusCode, {
    "content-type": "application/json; charset=utf-8",
    ...extraHeaders,
  });
  response.end(JSON.stringify(body));
}

async function streamedResponseFor(
  request: IncomingMessage,
  handler: LocalRuntimeRequestHandler | undefined,
): Promise<LocalRuntimeResponse | null> {
  if (!isStreamHandler(handler)) return null;
  return handler.handleStream({
    body: request, headers: request.headers, method: request.method, url: request.url,
  });
}

function isStreamHandler(handler: LocalRuntimeRequestHandler | undefined): handler is LocalRuntimeRequestHandler & LocalRuntimeStreamRequestHandler {
  return handler !== undefined && "handleStream" in handler;
}

const maximumRequestBytes = 1024 * 1024;

async function requestBody(request: IncomingMessage): Promise<unknown> {
  const chunks: Buffer[] = [];
  let size = 0;
  for await (const chunk of request) {
    const buffer = Buffer.from(chunk);
    size += buffer.length;
    if (size > maximumRequestBytes) throw new InvalidLocalRuntimeRequestError();
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
