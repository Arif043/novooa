# Twilio-Webhook

> Die Function `twilioWebhook` nimmt SMS- und WhatsApp-Nachrichten von Twilio an und startet passende Ereignis-Auslöser.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Die URL trägt die Zuordnung zu Team und Kanal:

```text
https://twiliowebhook-ilhamoy3ua-ey.a.run.app?teamId=<teamId>&channelId=<channelId>
```

Alle Cloud Functions laufen in Frankfurt (`europe-west3`). In der Twilio-Konsole
muss exakt diese URL inklusive Query-Parametern als `HTTP POST` stehen.

Ablauf:

1. `POST` mit `application/x-www-form-urlencoded` annehmen.
2. `X-Twilio-Signature` gegen `TWILIO_AUTH_TOKEN` prüfen.
3. Kommunikationskanal validieren.
4. Nachricht idempotent per `MessageSid` speichern.
5. Aktive Ereignis-Auslöser starten: `smsMessageReceived` bzw.
   `whatsappMessageReceived`; hat der Auslöser ein Kanal-Ziel
   (`target.kind == "channel"`), nur für diesen Kanal.

WhatsApp-Adressen werden normalisiert: `whatsapp:+…` wird als `+…`
gespeichert und so mit dem Kanal verglichen.

Im Functions Emulator wird ein fehlendes `TWILIO_AUTH_TOKEN` toleriert, in
Production ist es Pflicht.

## Siehe auch

- [Normalisierte Kanal-Ereignistypen](./kanal-ereignistypen.md)
- [Eingehende Nachrichten (Inbox)](./eingangs-nachrichten-inbox.md)
- [Fake-Kanalnachricht für Tests](./fake-kanalnachricht.md)
