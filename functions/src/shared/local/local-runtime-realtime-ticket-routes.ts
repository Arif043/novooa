import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {bearerTokenOf} from "./local-runtime-access-hooks.js";
import {ErrorResponse} from "./local-runtime-http-schemas.js";
import {type LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";

export type RealtimeTicketRoutesOptions = {tickets: Pick<LocalRuntimeRealtimeTicketStore, "issue">};

/**
 * Kurzlebiges Ticket für den WebSocket-Aufbau (Browser können dort keine Header setzen). Das Ticket
 * trägt die anfragende Sitzung weiter, damit die Verbindung mit ihr endet.
 */
export const realtimeTicketRoutes: FastifyPluginAsyncTypebox<RealtimeTicketRoutesOptions> = async (app, {tickets}) => {
  app.post("/v1/realtime/ticket", {
    schema: {response: {200: Type.Object({ticket: Type.String()}), 401: ErrorResponse}},
  }, async (request, reply) => {
    // Die Session-Prüfung der API lief schon; ohne Token kommt die Anfrage nur in Tests hierher.
    const sessionToken = bearerTokenOf(request);
    if (sessionToken === null) return reply.code(401).send({error: "Anmeldung erforderlich."});
    return {ticket: tickets.issue(sessionToken)};
  });
};
