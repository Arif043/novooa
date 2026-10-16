# Eingehende Nachrichten (Inbox)

> Jede eingehende Kanal-Nachricht wird idempotent in der Team-Inbox gespeichert, bevor Auslöser starten.

Gehört zu: [Zeitplan](../index/zeitplan.md)

```text
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageSid}
```

Die Provider-ID (`MessageSid` bei Twilio) ist der Dokument-Schlüssel. Ein
wiederholt zugestellter Webhook überschreibt daher dieselbe Nachricht, statt
sie doppelt anzulegen.

## Siehe auch

- [Twilio-Webhook](./twilio-webhook.md)
- [Fake-Kanalnachricht für Tests](./fake-kanalnachricht.md)
- [Kommunikationskanal-Datenmodell](./kommunikationskanal-datenmodell.md)
