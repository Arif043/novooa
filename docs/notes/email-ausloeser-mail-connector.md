# E-Mail-Auslöser über Mail-Connector

> E-Mail-Auslöser referenzieren einen Mail-Connector (Kundenpostfach), nie SendGrid.

Gehört zu: [Zeitplan](../index/zeitplan.md)

SendGrid bleibt auf novooa-eigene ausgehende System-E-Mails beschränkt und
erzeugt keine Kundenpostfach-Ereignisse. Bei
`eventConfig.source == "emailReceived"` zeigt das Ziel deshalb auf einen
Connector (`target.kind == "connector"`) statt auf einen Kanal; das Matching
vergleicht `target.id` mit der `connectorId` des Ereignisses.

Microsoft Graph liefert neue E-Mails bereits über seinen Connector; Gmail
folgt später. Mail-Connectoren bekommen je einen eigenen Provider-Adapter.

## Siehe auch

- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
- [Normalisierte Kanal-Ereignistypen](./kanal-ereignistypen.md)
- [Kommunikation](../features/kommunikation.md) — System-E-Mail und Connectoren
