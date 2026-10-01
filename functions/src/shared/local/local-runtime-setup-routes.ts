import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type IncomingHttpHeaders} from "node:http";
import {
  type LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {reachableAddresses} from "./local-runtime-reachable-addresses.js";

/** Nachweis für die Ersteinrichtung — bedient vom Lizenz-Service. */
export interface SetupAuthorization {
  requiresActivationTokenForSetup(): boolean;
  matchesActivationToken(token: unknown): boolean;
}

export type SetupRoutesOptions = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "hasCredential" | "setPassword">;
  authorization: SetupAuthorization;
};

const defaultPublishedPort = 8090;

/**
 * `GET`/`POST /v1/setup` — einmaliges Setzen des Betreiber-Passworts, über
 * den regulären Port. Verlangt dafür den Lizenz-Token, mit dem die Runtime
 * aktiviert wurde: Der Vertrauensanker ist **Besitz eines Geheimnisses**,
 * nicht Netzwerkposition. So kann niemand, der die Runtime zufällig zuerst
 * erreicht, das Passwort setzen — und die Einrichtung einer headless
 * installierten Runtime (VPS, NAS, Raspberry Pi) klappt von jedem Client aus.
 */
export const setupRoutes: FastifyPluginAsyncTypebox<SetupRoutesOptions> = async (app, {credentials, authorization}) => {
  app.get("/v1/setup", {
    schema: {response: {200: Type.Object({
      needsSetup: Type.Boolean(), requiresLicenseToken: Type.Boolean(), addresses: Type.Array(Type.String()),
    })}},
  }, async (request) => ({
    needsSetup: !await credentials.hasCredential(),
    requiresLicenseToken: authorization.requiresActivationTokenForSetup(),
    addresses: reachableAddresses(requestPortFrom(request.headers)),
  }));

  app.post("/v1/setup", {
    schema: {
      body: Type.Object({
        password: Type.String({minLength: 1, maxLength: 1000}),
        activationToken: Type.Optional(Type.String({maxLength: 100})),
      }),
      response: {204: Type.Null(), 403: ErrorResponse, 409: ErrorResponse},
    },
  }, async (request, reply) => {
    const {password, activationToken} = request.body;
    if (authorization.requiresActivationTokenForSetup() && !authorization.matchesActivationToken(activationToken)) {
      return reply.code(403).send({error: "Der Lizenz-Token passt nicht zu dieser Runtime."});
    }
    try {
      await credentials.setPassword(password);
      return reply.code(204).send(null);
    } catch (error) {
      if (!(error instanceof RuntimeAccessCredentialAlreadySetError)) throw error;
      return reply.code(409).send({error: error.message});
    }
  });
};

/**
 * Der Port kommt aus dem `Host`-Header der Anfrage, nicht aus der
 * Konfiguration: Im Container lauscht die Runtime auf 8080, Clients sprechen
 * aber den vom Docker-Host veröffentlichten 8090 an. Fällt ohne Port (etwa
 * hinter einem Reverse Proxy auf 443) auf den Standardport zurück.
 */
function requestPortFrom(headers: IncomingHttpHeaders): number {
  const port = Number(headers.host?.split(":")[1]);
  return Number.isSafeInteger(port) && port > 0 ? port : defaultPublishedPort;
}
