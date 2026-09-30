import { type FastifyInstance } from "fastify";
import { type LocalRuntimeRealtimeTicketStore } from "./local-runtime-realtime-ticket-store.js";
export class LocalRuntimeRealtimeTicketHttpHandler {
  constructor(private readonly tickets: LocalRuntimeRealtimeTicketStore) { }
  static registerRoutes(http: FastifyInstance, current: () => LocalRuntimeRealtimeTicketHttpHandler): void {
    http.post("/v1/realtime/ticket", async () => ({ ticket: current().tickets.issue() }));
  }
}
