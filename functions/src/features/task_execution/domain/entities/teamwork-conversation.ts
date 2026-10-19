/** Was im Gespräch einer Teamarbeit geschah: Aufträge, Antworten, Fehler, Prüfungen und das Ergebnis. */
export type TeamworkConversationKind = "task" | "answer" | "failure" | "reviewPassed" | "reviewRejected" | "result";

/**
 * Ein Eintrag im Gespräch einer Teamarbeit, strukturiert statt vorformatiert, damit der Client die
 * Beschriftungen übersetzt. Texte sind ungekürzt.
 */
export type TeamworkConversationEntry = {
  kind: TeamworkConversationKind;
  /** ISO-Zeitpunkt. */
  occurredAt: string;
  /** Der Mitarbeiter bei Auftrag, Antwort und Fehler. */
  memberName?: string;
  /** Auftrag, Antwort, Fehlermeldung, Befund der Prüfung oder das Ergebnis als JSON. */
  text: string;
  expectedResult?: string;
  boundaries?: string;
  /** Wie lange der Mitarbeiter für die Antwort brauchte. */
  durationMs?: number;
  /** Runde der Prüfung, ab 1. */
  round?: number;
};
