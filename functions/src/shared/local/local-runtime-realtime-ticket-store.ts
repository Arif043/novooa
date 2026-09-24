import {randomBytes} from "node:crypto";

const ticketBytes = 32;
const ticketLifetimeMs = 10 * 1000; // 10 Sekunden

/**
 * Kurzlebige, einmal verwendbare Tickets für den WebSocket-Verbindungsaufbau.
 *
 * Browser-`WebSocket` kann beim Verbindungsaufbau keine eigenen Header
 * setzen — irgendetwas muss also in der URL stehen. Das langlebige
 * Session-Token dort hineinzuschreiben wäre riskant (landet in
 * Server-/Proxy-Logs, bleibt 30 Tage gültig). Ein Ticket ist dagegen nur
 * 10 Sekunden gültig und nach einmaligem Gebrauch sofort tot — selbst ein
 * geloggtes Ticket ist praktisch wertlos.
 *
 * Bewusst In-Memory statt in SQLite: Die Lebensdauer ist kürzer als jede
 * denkbare Backup-/Restart-Relevanz, ein Prozess-Neustart macht offene
 * Tickets ohnehin ungültig (die Verbindung bräche dann sowieso ab).
 */
export class LocalRuntimeRealtimeTicketStore {
  private readonly expiresAtByTicket = new Map<string, number>();

  issue(): string {
    this.dropExpired();
    const ticket = randomBytes(ticketBytes).toString("hex");
    this.expiresAtByTicket.set(ticket, Date.now() + ticketLifetimeMs);
    return ticket;
  }

  /** Prüft das Ticket und verbraucht es dabei sofort (Einmalgebrauch). */
  consume(ticket: string): boolean {
    const expiresAt = this.expiresAtByTicket.get(ticket);
    this.expiresAtByTicket.delete(ticket);
    return expiresAt !== undefined && expiresAt > Date.now();
  }

  private dropExpired(): void {
    const now = Date.now();
    for (const [ticket, expiresAt] of this.expiresAtByTicket) {
      if (expiresAt <= now) this.expiresAtByTicket.delete(ticket);
    }
  }
}
