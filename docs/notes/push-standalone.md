# Push-Benachrichtigungen über das Relay

> Die Runtime leitet Geräte-Registrierungen und Push-Nachrichten mit ihrer Lizenz an `localRuntimePushRelay` weiter; Push ist optional und standardmäßig aus.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Die Desktop-App registriert ihren FCM-Token über `POST /v1/push-devices`.
  Der Relay prüft Signatur, Status und Arbeitsbereich erneut und speichert
  Tokens unter der Lizenz-ID.
- Relay-Vertrag transportneutral: `title`, `body`, Datenfeld
  (String → String); Befehle `registerDevice`, `removeDevice`, `send`.
  Freigaben sind nur ein Anwendungsfall davon, nicht Teil der Relay-API.
- Wartet eine Aufgabe auf Freigabe, sendet die Runtime über den Relay. Fehler
  werden protokolliert und blockieren die Aufgabe nicht.
- Standardmäßig aus, damit der macOS-Client ohne Apple-Zertifikat baut. Der
  Schalter erscheint nur, wenn Firebase dafür initialisiert ist.
- Signierte macOS-Auslieferung: `--dart-define=NOVOOA_PUSH_ENABLED=true` plus
  APNs-Credentials und `aps-environment`-Berechtigung.

Noch offen: Freigabe-Ereignisse zusätzlich als eigene Benachrichtigungsart
über das Relay zustellen.

## Siehe auch

- [Cloud-Endpunkte der Runtime](./runtime-cloud-endpunkte.md)
- [Lizenz freigeben](./lizenz-freigabe.md)
