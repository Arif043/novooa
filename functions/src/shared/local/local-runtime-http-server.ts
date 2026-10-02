import Fastify, {type FastifyInstance, type FastifyPluginAsync} from "fastify";
import fastifyCors from "@fastify/cors";
import fastifyStatic from "@fastify/static";
import {extname, resolve} from "node:path";
import {LocalRuntimeCorsPolicy} from "./local-runtime-cors-policy.js";
import {configureValidation} from "./local-runtime-validation.js";
import {SecureChannelStore} from "./secure-channel-store.js";
import {secureTransportRoutes} from "./secure-transport-routes.js";

export function createLocalRuntimeHttpServer(
  routes?: FastifyPluginAsync,
  webDirectory?: string,
  cors: LocalRuntimeCorsPolicy = new LocalRuntimeCorsPolicy(),
): FastifyInstance {
  const http = Fastify({bodyLimit: 1024 * 1024, exposeHeadRoutes: false, routerOptions: {ignoreTrailingSlash: true}});
  configureErrors(http);
  configureValidation(http);
  configureCors(http, cors);
  http.addContentTypeParser("application/onnx", (_request, payload, done) => done(null, payload));
  http.addContentTypeParser("application/zip", (_request, payload, done) => done(null, payload));
  http.register(secureTransportRoutes, {store: new SecureChannelStore(), target: http});
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

type HttpFailure = Error & {
  code?: string;
  validation?: ReadonlyArray<{instancePath?: string}>;
  validationContext?: string;
};

/** Auch von Tests genutzt, damit Schema-Fehler dort wie im Betrieb aussehen. */
export function configureErrors(http: FastifyInstance): void {
  http.setErrorHandler((error, _request, reply) => {
    const failure = error as HttpFailure;
    if (failure.validation) {
      return reply.code(400).send({error: "Ungültige Anfrage.", code: "invalid_request", field: invalidField(failure)});
    }
    if (failure.code?.startsWith("FST_ERR_CTP_")) {
      return reply.code(400).send({error: "Ungültige Anfrage.", code: "invalid_request"});
    }
    console.error(JSON.stringify({event: "local_runtime.http_failed", error: failure.message}));
    return reply.code(500).send({error: "Die lokale Runtime konnte die Anfrage nicht verarbeiten."});
  });
}

function invalidField(failure: HttpFailure): string {
  return `${failure.validationContext ?? ""}${failure.validation?.[0]?.instancePath ?? ""}`;
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
