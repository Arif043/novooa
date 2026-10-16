# Mail-Relay und Dead-Letter-Queue

> Microsoft-Graph-Postfächer laufen in Standalone vollständig im Cloud-Relay; die Runtime holt normalisierte `emailReceived`-Ereignisse ab und bestätigt sie.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- OAuth, Refresh-Tokens, Graph-Aufrufe, Versand und Webhooks bleiben in der
  Cloud. Die Runtime hält nur eine ausgehende HTTPS-Verbindung und
  authentifiziert sich mit ihrer signierten Lizenz.
- Nach idempotenter lokaler Verarbeitung bestätigt sie jedes Ereignis;
  fehlgeschlagene Zustellungen kommen mit begrenzten Wiederholungen erneut.
- Nach fünf unbestätigten oder abgelehnten Versuchen wandert das Ereignis in
  die team- und lizenzgebundene Dead-Letter-Queue:
  - `GET /v1/mail-relay/dead-letters`
  - `POST /v1/mail-relay/dead-letters/{eventId}/replay`

Warum: E-Mails gehen bei längerer Offline-Phase nicht verloren, ohne dass die
Cloud die Runtime direkt erreichen muss.

## Siehe auch

- [Firebase-Wake-up der Runtime](./runtime-firebase-wakeup.md)
- [Postfächer in der Runtime](./runtime-postfaecher.md)
- [Kommunikation](../features/kommunikation.md)
