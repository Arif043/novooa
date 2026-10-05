import Fastify, {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import {type ApplicationLogger} from "../logging/application-logger.js";
import {noFileEventPublisher} from "../../features/files/domain/repositories/file-event-publisher.js";
import {unavailableWebhookReceiver} from "../../features/webhooks/domain/usecases/receive-webhook.js";
import {configureErrors} from "./local-runtime-http-server.js";
import {configureValidation} from "./local-runtime-validation.js";
import {registerWorkspaceContext, type LocalRuntimeWorkspaceContext} from "./local-runtime-workspace-context.js";

export type TestRequest = {
  method?: string; url?: string; body: unknown;
  headers?: Readonly<Record<string, string | readonly string[] | undefined>>;
};
type TestResponse = {body: object; statusCode: number};
type Method = "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS";

export const silentLogger: ApplicationLogger = {
  info: () => undefined, error: () => undefined, exception: () => undefined,
  readableInfo: () => undefined, readableError: () => undefined,
};

export function testWorkspace(overrides: Partial<LocalRuntimeWorkspaceContext> = {}): LocalRuntimeWorkspaceContext {
  return {
    teamId: "team-1", userId: "user-1", logger: silentLogger, systemModelCatalog: undefined,
    taskWorkflow: new Proxy({}, {get: () => () => {throw new Error("Kein Task-Workflow im Test.");}}) as never,
    fileEvents: noFileEventPublisher, webhooks: unavailableWebhookReceiver,
    ...overrides,
  };
}

/**
 * Nur Tests: registriert ein Routen-Plugin wie im Betrieb (Fehler-Handler,
 * Validierung, Stream-Parser, Workspace-Kontext) einmal und führt Anfragen per
 * Fastify-Injection aus — Plugin-Zustand bleibt so zwischen Anfragen erhalten.
 * Liefert `null`, wenn keine Route passt.
 */
export function testingRoutes<Options extends object>(
  plugin: FastifyPluginAsync<Options>,
  options: Options,
  workspace: Partial<LocalRuntimeWorkspaceContext> = {},
) {
  let instance: Promise<FastifyInstance> | undefined;
  const server = () => instance ??= buildServer(plugin, options, workspace);
  async function handle(request: TestRequest, payload?: Buffer): Promise<TestResponse | null> {
    const body = payload ?? jsonPayload(request);
    const response = await (await server()).inject({
      method: (request.method ?? "GET") as Method, url: request.url ?? "/", payload: body,
      // Wie der App-Client: Content-Type nur, wenn tatsächlich ein Body mitgeht.
      headers: {...(body === undefined ? {} : {"content-type": "application/json"}), ...request.headers as Record<string, string>},
    });
    const responseBody = response.body.length === 0 ? {} : response.json<object>();
    return "testRouteMissing" in responseBody ? null : {body: responseBody, statusCode: response.statusCode};
  }
  async function handleStream(request: TestRequest & {body: AsyncIterable<Uint8Array>}) {
    const chunks: Buffer[] = [];
    for await (const chunk of request.body) chunks.push(Buffer.from(chunk));
    return handle(request, Buffer.concat(chunks));
  }
  return {handle, handleStream};
}

async function buildServer<Options extends object>(
  plugin: FastifyPluginAsync<Options>, options: Options, workspace: Partial<LocalRuntimeWorkspaceContext>,
): Promise<FastifyInstance> {
  const http = Fastify({exposeHeadRoutes: false, routerOptions: {ignoreTrailingSlash: true}});
  configureErrors(http);
  configureValidation(http);
  http.addContentTypeParser("application/onnx", (_request, stream, done) => done(null, stream));
  http.addContentTypeParser("application/zip", (_request, stream, done) => done(null, stream));
  registerWorkspaceContext(http, () => testWorkspace(workspace));
  await http.register(plugin, options);
  http.setNotFoundHandler((_request, reply) => reply.code(404).send({testRouteMissing: true}));
  await http.ready();
  return http;
}

function jsonPayload(request: TestRequest): string | undefined {
  if (request.method === undefined || request.method === "GET" || request.body === undefined) return undefined;
  return JSON.stringify(request.body);
}
