import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

export type LoginRoutesOptions = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "verifyPassword">;
  sessions: Pick<LocalRuntimeSessionStore, "createSession">;
};

/**
 * `POST /v1/auth/login` — tauscht das Betreiber-Passwort gegen ein
 * Session-Token. Von der Session-Pflicht ausgenommen (siehe
 * `local-runtime-access-hooks.ts`), sonst käme niemand an ein Token.
 */
export const loginRoutes: FastifyPluginAsyncTypebox<LoginRoutesOptions> = async (app, {credentials, sessions}) => {
  app.post("/v1/auth/login", {
    schema: {
      body: Type.Object({password: Type.String({maxLength: 1000})}),
      response: {200: Type.Object({token: Type.String()}), 401: ErrorResponse},
    },
  }, async (request, reply) => {
    const {password} = request.body;
    if (password.length === 0 || !await credentials.verifyPassword(password)) {
      return reply.code(401).send({error: "Passwort ist ungültig."});
    }
    return {token: await sessions.createSession()};
  });
};
