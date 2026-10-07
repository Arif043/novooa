import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {
  type LocalRuntimeAccessCredentialStore,
  RuntimeAccessCredentialAlreadySetError,
} from "./local-runtime-access-credential-store.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";

/** Nachweis für die Ersteinrichtung — bedient vom Lizenz-Service. */
export interface SetupAuthorization {
  requiresActivationTokenForSetup(): boolean;
  matchesActivationToken(token: unknown): boolean;
}

export type SetupRoutesOptions = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "hasCredential" | "setPassword">;
  authorization: SetupAuthorization;
};

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
      needsSetup: Type.Boolean(), requiresLicenseToken: Type.Boolean(),
    })}},
  }, async () => ({
    needsSetup: !await credentials.hasCredential(),
    requiresLicenseToken: authorization.requiresActivationTokenForSetup(),
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
