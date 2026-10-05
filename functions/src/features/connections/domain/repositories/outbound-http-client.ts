export type OutboundHttpRequest = {
  teamId: string;
  /** Mit Verbindung: `url` ist ein Pfad (oder eine Adresse derselben Origin) und die Anmeldung wird ergänzt. */
  connectionId?: string;
  method: "GET" | "POST" | "PUT" | "PATCH" | "DELETE";
  url: string;
  query: Array<{name: string; value: string}>;
  headers: Record<string, string>;
  body?: string;
  timeoutMs: number;
};

export type OutboundHttpResponse = {
  status: number;
  /** Namen in Kleinbuchstaben, ohne `set-cookie`. */
  headers: Record<string, string>;
  body: string;
};

/** Die Anfrage kam nicht zustande (Netzwerk, Zeitlimit, zu große Antwort, ungültige Eingabe); die Meldung ist deutsch und ohne Geheimnisse. */
export class OutboundHttpError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "OutboundHttpError";
  }
}

export interface OutboundHttpClient {
  /** Wirft `OutboundHttpError`, `ConnectionNotFoundError` oder `ConnectionAuthError`. HTTP-Fehlerstatus sind keine Fehler, sondern Antworten. */
  send(request: OutboundHttpRequest): Promise<OutboundHttpResponse>;
}
