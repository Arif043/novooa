export type AuthorizedConnection = {
  baseUrl: string;
  /** Kopfzeilen, die die Anmeldung tragen (Header-Namen in Kleinbuchstaben). */
  headers: Record<string, string>;
};

/** Liefert Executoren eine fertig angemeldete Verbindung, ohne dass sie das Geheimnis selbst sehen. */
export interface ConnectionAuthorizer {
  /** Wirft `ConnectionNotFoundError` oder `ConnectionAuthError`. */
  authorize(teamId: string, connectionId: string): Promise<AuthorizedConnection>;
}
