# Kommunikation

> Kommunikation trennt novooa-eigene System-E-Mails strikt von den Postfächern und Kanälen der Kundschaft; Kanäle sind eine gemeinsame Abstraktion für E-Mail, WhatsApp, SMS und Künftiges.

## Grundlagen

- [System-E-Mail über SendGrid](../notes/system-email-sendgrid.md)
- [Mail-Connectoren](../notes/mail-connectoren.md)
- [Kommunikationskanal-Datenmodell](../notes/kommunikationskanal-datenmodell.md)
- [Sicherheit der Kommunikation](../notes/kommunikation-sicherheit.md)

## Microsoft Graph

- [Token- und Subscription-Pflege (Microsoft Graph)](../notes/graph-token-und-subscriptions.md)
- [Mail-Relay und Dead-Letter-Queue](../notes/mail-relay-dead-letter.md) (Standalone)
- [Postfächer in der Runtime](../notes/runtime-postfaecher.md)

## Twilio (SMS, WhatsApp)

- [Twilio-Webhook](../notes/twilio-webhook.md)
- [Twilio über den Cloud-Relay](../notes/twilio-relay.md)
- [Fake-Kanalnachricht für Tests](../notes/fake-kanalnachricht.md)

## Ereignisse und Bausteine

- [Normalisierte Kanal-Ereignistypen](../notes/kanal-ereignistypen.md)
- [Eingehende Nachrichten (Inbox)](../notes/eingangs-nachrichten-inbox.md)
- [E-Mail-Auslöser über Mail-Connector](../notes/email-ausloeser-mail-connector.md)
- [Kanal-Bausteine](../notes/kanal-bausteine.md)

## Oberfläche

- [Einstellungs-Tab „Kommunikation“](../notes/kommunikation-einstellungen.md)

## Offene Punkte

1. Connector-Auswahl im Sende-Baustein ergänzen.
2. `SystemEmailSender` als backend-internen Dienst bereitstellen.
3. Gmail-Adapter mit OAuth, Empfang und Antwortversand.
4. IMAP/SMTP als generischen Connector evaluieren.
5. WhatsApp, SMS, Telegram und Instagram als Bausteine freischalten (derzeit
   „Bald verfügbar“).

## Verwandt

- [Zeitplan](./zeitplan.md)
- [Aufgabe](./aufgabe.md)
- [Lokale Runtime](./lokale-runtime.md)
