# Postfächer in der Runtime

> Der Tab „Kommunikation“ zeigt die E-Mail-Postfächer der Runtime; die Liste kommt über das Relay und wird nur bei einem Wake-up verworfen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Relay-Befehl `listMailConnectors` liefert nur Anzeigedaten (ID, Adresse,
  Name, Status), nie Zugangsdaten; die Runtime reicht sie über
  `GET /v1/mail-connectors` weiter.
- Das Mail-Relay ist Quelle der Wahrheit; `MailConnectorListCache` hält die
  Liste ohne Zeitablauf. Ändert sich ein Postfach, erhöht das Relay
  `connectorsRevision`; `RuntimeWakeupHandler` leert den Cache und meldet das
  Realtime-Thema `mail-connectors`, erst dann lädt die App neu.
- Reißt der Firestore-Listener ab, wird der Cache ebenfalls geleert, weil
  Ereignisse fehlen könnten. Kein Nachfragen im Takt.
- „Postfach verbinden“: `POST /v1/mail-connectors/microsoft/authorization`;
  abgelaufene Anmeldung bietet „Postfach neu verbinden“.
- Dieselbe Liste speist das Ziel-Sheet für E-Mail-Auslöser.

## Siehe auch

- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
- [Mail-Relay und Dead-Letter-Queue](./mail-relay-dead-letter.md)
