# Mail-Connectoren

> Ein Mail-Connector bindet ein konkretes Kundenpostfach technisch an und speist daraus einen E-Mail-Kommunikationskanal; OAuth und Tokens bleiben im Backend.

Gehört zu: [Kommunikation](../index/kommunikation.md)

| Provider | Zugriffsweg | Status |
| --- | --- | --- |
| Gmail / Google Workspace | OAuth und Gmail API | geplant |
| Microsoft 365 / Outlook.com | OAuth und Microsoft Graph | implementiert |
| klassische Mailanbieter | IMAP/SMTP | zu evaluieren |

- `CommunicationChannel` ist die fachliche Abstraktion für E-Mail, WhatsApp,
  SMS und künftige Kanäle; der Connector kapselt Autorisierung,
  Berechtigungen, verschlüsselte, widerrufbare Zugangsdaten und den
  Provider-Lebenszyklus, statt sie als Kanal-Konfiguration offenzulegen.
- **Microsoft Graph:** PKCE, serverseitiger OAuth-Callback, delegierte
  Berechtigungen `Mail.Read`, `Mail.Send`, `User.Read`, `offline_access`. Neue
  Mails kommen per Graph-Webhook; ein Scheduler erneuert die Subscriptions.
- Ein Connector normalisiert neue Mails zu `EmailReceivedEvent`, speichert sie
  in der Team-Inbox und startet passende Auslöser.
- Manueller Versand: Callable `sendMicrosoftMailConnectorMessage`.
- Standalone: Der Connector läuft vollständig im Cloud-Relay
  ([Mail-Relay und Dead-Letter-Queue](./mail-relay-dead-letter.md)).

## Siehe auch

- [Token- und Subscription-Pflege (Microsoft Graph)](./graph-token-und-subscriptions.md)
- [Sicherheit der Kommunikation](./kommunikation-sicherheit.md)
- [Kanal-Bausteine](./kanal-bausteine.md)
