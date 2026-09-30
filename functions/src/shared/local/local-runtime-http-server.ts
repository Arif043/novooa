import Fastify, {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import fastifyCors from "@fastify/cors";
import fastifyStatic from "@fastify/static";
import {extname, resolve} from "node:path";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";

export function createLocalRuntimeHttpServer(
  routes?: FastifyPluginAsync,
  webDirectory?: string,
  cors: LocalRuntimeCorsPolicy = new LocalRuntimeCorsPolicy(),
): FastifyInstance {
  const http = Fastify({bodyLimit: 1024 * 1024, exposeHeadRoutes: false, routerOptions: {ignoreTrailingSlash: true}});
  configureErrors(http);
  configureCors(http, cors);
  http.addContentTypeParser("application/onnx", (_request, payload, done) => done(null, payload));
  http.get("/healthz", async () => ({status: "ok"}));
  if (routes !== undefined) http.register(routes);
  if (webDirectory !== undefined) configureWebFiles(http, webDirectory);
  else http.setNotFoundHandler((_request, reply) => reply.code(404).send({error: "Endpunkt nicht gefunden."}));
  return http;
}

function configureCors(http: FastifyInstance, cors: LocalRuntimeCorsPolicy): void {
  http.addHook("onRequest", async (request, reply) => {
    if (!cors.allows(request.headers.origin, request.headers.host)) {
      return reply.code(403).send({error: "Herkunft nicht erlaubt."});
    }
  });
  http.register(fastifyCors, {
    delegator: (request, done) => done(null, {
      origin: cors.allows(request.headers.origin, request.headers.host),
      methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
      allowedHeaders: ["authorization", "content-type"], maxAge: 600,
    }),
  });
}

function configureErrors(http: FastifyInstance): void {
  http.setErrorHandler((error, _request, reply) => {
    const failure = error as Error & {code?: string; validation?: unknown};
    if (failure.validation || failure.code?.startsWith("FST_ERR_CTP_")) {
      return reply.code(400).send({error: "Ungültige lokale Anfrage."});
    }
    console.error(JSON.stringify({event: "local_runtime.http_failed", error: failure.message}));
    return reply.code(500).send({error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."});
  });
}

function configureWebFiles(http: FastifyInstance, directory: string): void {
  http.register(fastifyStatic, {
    root: resolve(directory),
    allowedPath: (pathname) => pathname !== "/v1" && !pathname.startsWith("/v1/"),
  });
  http.setNotFoundHandler((request, reply) => {
    const pathname = decodeURIComponent(request.url.split("?")[0]);
    const isWebPage = ["GET", "HEAD"].includes(request.method) &&
      pathname !== "/v1" && !pathname.startsWith("/v1/") && pathname !== "/healthz" && extname(pathname) === "";
    return isWebPage ? reply.sendFile("index.html") : reply.code(404).send({error: "Endpunkt nicht gefunden."});
  });
}
