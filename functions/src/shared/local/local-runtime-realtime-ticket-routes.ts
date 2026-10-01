import {type FastifyPluginAsyncTypebox, Type} from "@fastify/type-provider-typebox";
import {type LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";

export type RealtimeTicketRoutesOptions = {tickets: Pick<LocalRuntimeRealtimeTicketStore, "issue">};

/** Kurzlebiges Ticket für den WebSocket-Aufbau (Browser können dort keine Header setzen). */
export const realtimeTicketRoutes: FastifyPluginAsyncTypebox<RealtimeTicketRoutesOptions> = async (app, {tickets}) => {
  app.post("/v1/realtime/ticket", {
    schema: {response: {200: Type.Object({ticket: Type.String()})}},
  }, async () => ({ticket: tickets.issue()}));
};
