# Twilio über den Cloud-Relay

> Twilio zeigt nie direkt auf eine lokale Installation; ein- und ausgehende Nachrichten laufen über den novooa Cloud-Relay.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```text
Eingehend:  Twilio → Cloud-Relay → lokale Runtime → SQLite task_runs → lokaler Worker
Ausgehend:  lokale Runtime → Cloud-Relay → Twilio
```

- Der Relay verwaltet Twilio-Credentials und Subaccounts zentral.
- Die Runtime authentifiziert sich über ein Geräte-/Workspace-Token.
- Ist die Runtime offline, kann der Relay Ereignisse puffern und später
  zustellen.

Stand: geplanter Weg. Der Einstellungs-Tab „Kommunikation“ zeigt in
Standalone derzeit keine SMS-/WhatsApp-Kanäle (siehe
[Postfächer in der Runtime](./runtime-postfaecher.md)).

## Siehe auch

- [Twilio-Webhook](./twilio-webhook.md) — Cloud-Eingang
- [Kommunikationskanal-Datenmodell](./kommunikationskanal-datenmodell.md)
