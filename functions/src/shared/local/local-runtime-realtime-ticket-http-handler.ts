import {
  type LocalRuntimeRequest,
  type LocalRuntimeRequestHandler,
  type LocalRuntimeResponse,
} from "./local-runtime-http-server.js";
import {type LocalRuntimeRealtimeTicketStore} from "./local-runtime-realtime-ticket-store.js";

/**
 * `POST /v1/realtime/ticket` — läuft wie jeder andere Endpunkt hinter dem
 * `LocalRuntimeSessionAuthGate` (verlangt also bereits ein gültiges
 * `Authorization: Bearer <token>`) und tauscht das gegen ein kurzlebiges
 * Ticket für den WebSocket-Verbindungsaufbau (siehe
 * `LocalRuntimeRealtimeTicketStore`).
 */
export class LocalRuntimeRealtimeTicketHttpHandler implements LocalRuntimeRequestHandler {
  constructor(private readonly tickets: LocalRuntimeRealtimeTicketStore) {}

  async handle(request: LocalRuntimeRequest): Promise<LocalRuntimeResponse | null> {
    if (request.url !== "/v1/realtime/ticket" || request.method !== "POST") return null;
    return {body: {ticket: this.tickets.issue()}, statusCode: 200};
  }
}
