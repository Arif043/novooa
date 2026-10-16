# Fake-Kanalnachricht für Tests

> `dispatchFakeChannelMessage` testet Kanal-Auslöser ohne Provider-Guthaben über denselben Weg wie ein echter Webhook.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Die Callable Function ist authentifiziert und nutzt den persönlichen
Team-Kontext. Sie lädt `communicationChannels/{channelId}`, schreibt eine
Fake-Nachricht in die Inbox und startet danach dieselben Kanal-Auslöser wie
der [Twilio-Webhook](./twilio-webhook.md).

Im UI: `Einstellungen > Kommunikation`, pro Kanal „Testnachricht“. Ein
entsprechender Test für E-Mail-Connectoren fehlt noch.

## Siehe auch

- [Eingehende Nachrichten (Inbox)](./eingangs-nachrichten-inbox.md)
- [Worker für fällige Auslöser](./faellige-ausloeser-worker.md) — lokal manuell auslösen
