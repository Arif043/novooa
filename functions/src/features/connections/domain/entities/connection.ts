/** Wie sich die Runtime gegenüber dem externen System ausweist. Geheimnisse gehören nicht hierher. */
export type ConnectionAuth =
  | {kind: "apiKey"; headerName: string}
  | {kind: "bearer"}
  | {kind: "oauthClientCredentials"; tokenUrl: string; clientId: string; scope?: string};

export type Connection = {
  id: string;
  teamId: string;
  name: string;
  /** Ohne abschließenden Schrägstrich. */
  baseUrl: string;
  auth: ConnectionAuth;
  /** Ändert sich mit jeder Bearbeitung (auch des Geheimnisses); Schlüssel für Token-Zwischenspeicher. */
  updatedAt: string;
};

export type ConnectionInput = Pick<Connection, "name" | "baseUrl" | "auth">;

/** Ungültige Eingabe zu einer Verbindung — die Meldung ist für Nutzer:innen bestimmt. */
export class ConnectionRequestError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConnectionRequestError";
  }
}

export class ConnectionNotFoundError extends Error {
  constructor(readonly connectionId: string) {
    super("Die Verbindung wurde nicht gefunden. Wurde sie gelöscht?");
    this.name = "ConnectionNotFoundError";
  }
}

/** Die Anmeldung beim externen System ist fehlgeschlagen (Token, fehlendes Geheimnis). */
export class ConnectionAuthError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "ConnectionAuthError";
  }
}
