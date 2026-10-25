# Kanal-Bausteine

> „E-Mail lesen“ und „Nachricht lesen“ übersetzen das auslösende Ereignis in benannte Werte; „Nachricht senden“ antwortet über den passenden Kanal.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **Lesen** (`readEmail`, `readChannelEvent`): Nachrichtentext als `value`,
  dazu `sender`, `subject` (nur E-Mail), `receivedAt`. Microsoft-Graph-
  Connectoren liefern neue E-Mails per Webhook als Run-Event; Gmail fehlt.
- **Senden** (`sendChannelMessage`): liefert `recipient`, `channelId`,
  `providerMessageId`. Gesendet wird über das Postfach im Mail-Relay. SendGrid ist nur der
  globale System-E-Mail-Dienst und für Arbeitspläne nicht nutzbar.
- Bei einem Graph-E-Mail-Event nutzt „Nachricht senden“ ohne `connectorId`
  automatisch das auslösende Postfach und setzt `Re: <Betreff>`. Unabhängig
  gestartet braucht er die `connectorId` eines aktiven Connectors.
- Palette: Nur E-Mail ist anwählbar; WhatsApp, SMS, Telegram und Instagram
  sind deaktiviert mit „(Bald verfügbar)“ (`ChannelEventKind.isAvailable`).

## Siehe auch

- [E-Mail-Auslöser über Mail-Connector](./email-ausloeser-mail-connector.md)
- [Kommunikation](../index/kommunikation.md)
