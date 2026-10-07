import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {sendSessionRequired, bearerTokenOf} from "./local-runtime-access-hooks.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {type LocalRuntimeRealtimeConnections} from "./local-runtime-realtime-connections.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

export type SessionRoutesOptions = {
  sessions: Pick<LocalRuntimeSessionStore, "deleteSession" | "deleteOtherSessions">;
  connections: Pick<LocalRuntimeRealtimeConnections, "closeSession" | "closeOtherSessions">;
};

/**
 * Abmelden und Widerrufen. Beide Routen liegen hinter der Session-Prüfung der
 * API und wirken auf die Sitzung, mit der die Anfrage kommt. Offene
 * Realtime-Verbindungen der beendeten Sitzungen werden sofort geschlossen.
 */
export const sessionRoutes: FastifyPluginAsyncTypebox<SessionRoutesOptions> = async (app, {sessions, connections}) => {
  app.post("/v1/auth/logout", {
    schema: {response: {204: Type.Null(), 401: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    await sessions.deleteSession(token);
    connections.closeSession(token);
    return reply.code(204).send(null);
  });

  app.post("/v1/auth/sessions/revoke-others", {
    schema: {response: {200: Type.Object({revoked: Type.Integer()}), 401: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    const revoked = await sessions.deleteOtherSessions(token);
    connections.closeOtherSessions(token);
    return {revoked};
  });
};
