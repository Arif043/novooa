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
  private readonly ticketsByValue = new Map<string, {expiresAt: number; sessionToken: string}>();

  /** Stellt ein Ticket für die Sitzung aus, die es anfordert — die Verbindung bleibt an sie gebunden. */
  issue(sessionToken: string): string {
    this.dropExpired();
    const ticket = randomBytes(ticketBytes).toString("hex");
    this.ticketsByValue.set(ticket, {expiresAt: Date.now() + ticketLifetimeMs, sessionToken});
    return ticket;
  }

  /** Prüft das Ticket, verbraucht es sofort (Einmalgebrauch) und liefert die Sitzung dazu. */
  consume(ticket: string): string | null {
    const issued = this.ticketsByValue.get(ticket);
    this.ticketsByValue.delete(ticket);
    return issued !== undefined && issued.expiresAt > Date.now() ? issued.sessionToken : null;
  }

  private dropExpired(): void {
    const now = Date.now();
    for (const [ticket, issued] of this.ticketsByValue) {
      if (issued.expiresAt <= now) this.ticketsByValue.delete(ticket);
    }
  }
}
