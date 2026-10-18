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

export interface OutboundHttpClient {
  /** Kommt die Anfrage nicht zustande, wirft die Infrastruktur ihre Exception. HTTP-Fehlerstatus sind keine Fehler, sondern Antworten. */
  send(request: OutboundHttpRequest): Promise<OutboundHttpResponse>;
}
