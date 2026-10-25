# Kommunikation

> Kommunikation trennt novooa-eigene System-E-Mails strikt von den Postfächern der Kundschaft; die Runtime erreicht ihre Postfächer über das Mail-Relay.

## Grundlagen

- [System-E-Mail über SendGrid](../notes/system-email-sendgrid.md)
- [Mail-Connectoren](../notes/mail-connectoren.md)
- [Sicherheit der Kommunikation](../notes/kommunikation-sicherheit.md)

## Microsoft Graph

- [Token- und Subscription-Pflege (Microsoft Graph)](../notes/graph-token-und-subscriptions.md)
- [Mail-Relay und Dead-Letter-Queue](../notes/mail-relay-dead-letter.md)
- [Postfächer in der Runtime](../notes/runtime-postfaecher.md)

## Ereignisse und Bausteine

- [Normalisierte Kanal-Ereignistypen](../notes/kanal-ereignistypen.md)
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
