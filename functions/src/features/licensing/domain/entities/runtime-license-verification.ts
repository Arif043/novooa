/**
 * Antwort des Lizenz-Gateways auf die regelmäßige Prüfung einer Aktivierung.
 *
 * - `active`: Die Aktivierung gilt weiter.
 * - `revoked`: Die Lizenz wurde gelöscht, freigegeben, ist abgelaufen oder gehört
 *   zu einer anderen Aktivierung — die Runtime muss sich sperren.
 *
 * Alles andere (Netzwerkfehler, Serverfehler, unbekannte Antwort) ist kein Urteil
 * über die Lizenz: Die Runtime läuft weiter und prüft beim nächsten Mal erneut.
 */
export type RuntimeLicenseVerdict = "active" | "revoked";

/** Ergebnis einer Prüfung aus Sicht der Runtime. */
export type RuntimeLicenseCheck = RuntimeLicenseVerdict | "notActivated";
