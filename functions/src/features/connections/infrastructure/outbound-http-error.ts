/** Die Anfrage kam nicht zustande (Netzwerk, Zeitlimit, zu große Antwort, ungültige Eingabe); die Meldung ist deutsch und ohne Geheimnisse. */
export class OutboundHttpError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "OutboundHttpError";
  }
}
