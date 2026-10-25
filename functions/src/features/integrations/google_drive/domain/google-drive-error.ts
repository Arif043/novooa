/** Fehler eines Drive-Bausteins; die Meldung ist für Nutzer:innen bestimmt und erscheint in den Aktivitäten. */
export class GoogleDriveError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "GoogleDriveError";
  }
}
