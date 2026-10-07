import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type LocalRuntimeAccessCredentialStore} from "./local-runtime-access-credential-store.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";

type PasswordRoutesOptions = {
  credentials: Pick<LocalRuntimeAccessCredentialStore, "updatePassword">;
};

/** Hinter den Lizenz- und Session-Hooks: angemeldete Betreiber setzen ein neues Passwort. */
export const passwordRoutes: FastifyPluginAsyncTypebox<PasswordRoutesOptions> = async (app, {credentials}) => {
  app.put("/v1/auth/password", {
    schema: {
      body: Type.Object({password: Type.String({minLength: 6, maxLength: 1000})}, {additionalProperties: false}),
      response: {204: Type.Null(), 400: ErrorResponse, 401: ErrorResponse},
    },
  }, async (request, reply) => {
    await credentials.updatePassword(request.body.password);
    return reply.code(204).send(null);
  });
};
