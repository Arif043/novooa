import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {sendSessionRequired, bearerTokenOf} from "./local-runtime-access-hooks.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {type LocalRuntimeRealtimeConnections} from "./local-runtime-realtime-connections.js";
import {type LocalRuntimeSessionStore} from "./local-runtime-session-store.js";

export type SessionRoutesOptions = {
  sessions: Pick<LocalRuntimeSessionStore,
    "deleteSession" | "deleteOtherSessions" | "deleteOwnSession" | "listSessionsOf" | "isActive">;
  connections: Pick<LocalRuntimeRealtimeConnections, "closeSession" | "closeInactive">;
};

const SessionDto = Type.Object({
  id: Type.String(),
  current: Type.Boolean(),
  createdAt: Type.String(),
  lastUsedAt: Type.String(),
  device: Type.Object({app: Type.String(), os: Type.String(), browser: Type.Union([Type.String(), Type.Null()])}),
});

/**
 * Abmelden, eigene Sitzungen ansehen und widerrufen. Alle Routen liegen hinter der Session-Prüfung der API und
 * wirken nur auf das Konto der anfragenden Sitzung. Offene Realtime-Verbindungen beendeter Sitzungen werden
 * sofort geschlossen.
 */
export const sessionRoutes: FastifyPluginAsyncTypebox<SessionRoutesOptions> = async (app, {sessions, connections}) => {
  const closeEnded = () => connections.closeInactive((sessionToken) => sessions.isActive(sessionToken));

  app.post("/v1/auth/logout", {
    schema: {response: {204: Type.Null(), 401: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    await sessions.deleteSession(token);
    connections.closeSession(token);
    return reply.code(204).send(null);
  });

  app.get("/v1/auth/sessions", {
    schema: {response: {200: Type.Object({items: Type.Array(SessionDto)}), 401: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    return {items: await sessions.listSessionsOf(request.actor.uid, token)};
  });

  app.delete("/v1/auth/sessions/:id", {
    schema: {params: Type.Object({id: Type.String({maxLength: 64})}),
      response: {204: Type.Null(), 401: ErrorResponse, 404: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    if (!await sessions.deleteOwnSession(request.actor.uid, request.params.id, token)) {
      return reply.code(404).send({error: "Diese Sitzung gibt es nicht mehr.", code: "session_not_found"});
    }
    await closeEnded();
    return reply.code(204).send(null);
  });

  app.post("/v1/auth/sessions/revoke-others", {
    schema: {response: {200: Type.Object({revoked: Type.Integer()}), 401: ErrorResponse}},
  }, async (request, reply) => {
    const token = bearerTokenOf(request);
    if (token === null) return sendSessionRequired(reply);
    const revoked = await sessions.deleteOtherSessions(token, request.actor.uid);
    await closeEnded();
    return {revoked};
  });
};
