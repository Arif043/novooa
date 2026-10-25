/** Kurzlebige Zugriffstokens für ein verbundenes Google-Konto, wie sie die Runtime für API-Aufrufe braucht. */
export interface GoogleAccessTokens {
  token(accountId: string): Promise<string>;
  /** Google hat das Token abgelehnt (401): Der nächste Aufruf holt ein neues. */
  invalidate(accountId: string): void;
}

/** Das Konto muss neu verbunden werden; Wiederholen hilft nicht. Die Meldung ist für Nutzer:innen bestimmt. */
export class GoogleReauthorizationRequiredError extends Error {
  constructor() {
    super("Die Google-Anmeldung ist abgelaufen. Verbinde das Konto in den Einstellungen unter „Verbindungen“ neu.");
    this.name = "GoogleReauthorizationRequiredError";
  }
}
