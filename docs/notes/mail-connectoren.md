# Mail-Connectoren

> Ein Mail-Connector bindet ein konkretes Kundenpostfach technisch an und speist daraus einen E-Mail-Kommunikationskanal; OAuth und Tokens bleiben im Backend.

Gehört zu: [Kommunikation](../index/kommunikation.md)

| Provider | Zugriffsweg | Status |
| --- | --- | --- |
| Gmail / Google Workspace | OAuth und Gmail API | geplant |
| Microsoft 365 / Outlook.com | OAuth und Microsoft Graph | implementiert |
| klassische Mailanbieter | IMAP/SMTP | zu evaluieren |

- `CommunicationChannel` ist die fachliche Abstraktion für Kanäle; der
  Connector kapselt Autorisierung,
  Berechtigungen, verschlüsselte, widerrufbare Zugangsdaten und den
  Provider-Lebenszyklus, statt sie als Kanal-Konfiguration offenzulegen.
- **Microsoft Graph:** PKCE, serverseitiger OAuth-Callback, delegierte
  Berechtigungen `Mail.Read`, `Mail.Send`, `User.Read`, `offline_access`. Neue
  Mails kommen per Graph-Webhook; ein Scheduler erneuert die Subscriptions.
- Ein Connector gehört genau einer Runtime-Lizenz (`runtimeLicenseId`). Neue
  Mails normalisiert er zu `EmailReceivedEvent` und reiht sie für diese
  Runtime ein; die Runtime holt sie ab und startet passende Auslöser.
- Der Connector läuft vollständig im Mail-Relay in Firebase
  ([Mail-Relay und Dead-Letter-Queue](./mail-relay-dead-letter.md)); auch das
  Senden geht über das Relay.

## Siehe auch

- [Token- und Subscription-Pflege (Microsoft Graph)](./graph-token-und-subscriptions.md)
- [Sicherheit der Kommunikation](./kommunikation-sicherheit.md)
- [Kanal-Bausteine](./kanal-bausteine.md)
