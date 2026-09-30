import Fastify, {type FastifyInstance} from "fastify";

export type TestRequest = {
  method?: string; url?: string; body: unknown;
  headers?: Readonly<Record<string, string | readonly string[] | undefined>>;
};
type TestResponse = {body: object; statusCode: number};
type RegisteredController = {registerRoutes(http: FastifyInstance, current: () => unknown): void};

/** Nur Tests: bestehende Assertions werden über echte Fastify-Injection ausgeführt. */
export function testingRoutes(controller: object) {
  async function handle(request: TestRequest, payload?: Buffer): Promise<TestResponse | null> {
    const http = Fastify({exposeHeadRoutes: false, routerOptions: {ignoreTrailingSlash: true}});
    (controller.constructor as unknown as RegisteredController).registerRoutes(http, () => controller);
    http.addContentTypeParser("application/onnx", (_request, stream, done) => done(null, stream));
    http.setNotFoundHandler((_request, reply) => reply.code(404).send({testRouteMissing: true}));
    try {
      const response = await http.inject({
        method: (request.method ?? "GET") as "GET" | "POST" | "PUT" | "DELETE" | "PATCH" | "HEAD" | "OPTIONS", url: request.url ?? "/",
        payload: payload ?? (request.method === "GET" ? undefined : JSON.stringify(request.body)),
        headers: {"content-type": "application/json", ...request.headers as Record<string, string>},
      });
      const body = response.body.length === 0 ? {} : response.json<object>();
      return "testRouteMissing" in body ? null : {body, statusCode: response.statusCode};
    } finally { await http.close(); }
  }
  async function handleStream(request: TestRequest & {body: AsyncIterable<Uint8Array>}) {
    const chunks: Buffer[] = [];
    for await (const chunk of request.body) chunks.push(Buffer.from(chunk));
    return handle(request, Buffer.concat(chunks));
  }
  return {handle, handleStream};
}
