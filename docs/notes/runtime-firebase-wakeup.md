# Firebase-Wake-up der Runtime

> Die Runtime hört als technischer Firebase-User auf `localRuntimeWakeups/{licenseId}`; der Relay schreibt dort nur Revisionsnummern, nie Inhalte.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Nach Aktivierung und bei jedem Start fordert die Runtime mit signierter
  Lizenz **und** Aktivierungsgeheimnis ein kurzlebiges Custom-Token an und
  meldet sich bei Firebase Auth an.
- Revisionen: `communicationRevision` (neue Mails) und `connectorsRevision`
  (Postfächer geändert). Inhalte bleiben in der Relay-Queue; die Runtime
  holt sie per `pull`, verarbeitet lokal und sendet `ack` oder `reject`.
- Firestore stellt den Listener nach Netzunterbrechungen selbst wieder her
  und liefert den aktuellen Zustand erneut. Weil die Revision erhalten bleibt,
  gibt es kein zeitbasiertes Fallback-Polling.
- Claims: nur `localRuntime`, `runtimeLicenseId`, `runtimeActivationId` und
  die Scopes `communication`, `pushNotifications`. Die Regeln erlauben nur das
  Lesen des eigenen Wake-up-Dokuments.
- Token und Sitzung sind flüchtig; die Runtime speichert weder
  Firebase-Credentials noch Admin-Schlüssel.

## Siehe auch

- [Mail-Relay und Dead-Letter-Queue](./mail-relay-dead-letter.md)
- [Postfächer in der Runtime](./runtime-postfaecher.md)
- [Cloud-Endpunkte der Runtime](./runtime-cloud-endpunkte.md)
