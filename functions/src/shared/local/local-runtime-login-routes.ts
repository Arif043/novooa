import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {type LoginAttemptLimiter} from "./local-runtime-login-rate-limiter.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

export type LoginRoutesOptions = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "verifyPassword">;
  sessions: Pick<LocalRuntimeSessionStore, "createSession">;
  limiter: LoginAttemptLimiter;
};

/**
 * `POST /v1/auth/login` — tauscht das Betreiber-Passwort gegen ein
 * Session-Token. Von der Session-Pflicht ausgenommen (siehe
 * `local-runtime-access-hooks.ts`), sonst käme niemand an ein Token.
 *
 * Jeder Versuch kostet einen scrypt-Hash; die Begrenzung greift deshalb vor
 * der Passwortprüfung. Hinter einem Reverse Proxy ist `request.ip` die Adresse
 * des Proxys — dann teilen sich alle Clients die Client-Stufe.
 */
export const loginRoutes: FastifyPluginAsyncTypebox<LoginRoutesOptions> = async (app, {credentials, sessions, limiter}) => {
  app.post("/v1/auth/login", {
    schema: {
      body: Type.Object({password: Type.String({maxLength: 1000})}),
      response: {200: Type.Object({token: Type.String()}), 401: ErrorResponse, 429: ErrorResponse},
    },
  }, async (request, reply) => {
    const attempt = await limiter.take(request.ip);
    if (!attempt.allowed) {
      return reply.code(429).header("retry-after", String(attempt.retryAfterSeconds)).send({
        error: `Zu viele Anmeldeversuche. Bitte in ${attempt.retryAfterSeconds} Sekunden erneut versuchen.`,
      });
    }
    const {password} = request.body;
    if (password.length === 0 || !await credentials.verifyPassword(password)) {
      return reply.code(401).send({error: "Passwort ist ungültig."});
    }
    return {token: await sessions.createSession()};
  });
};
