# Ereignisquellen-Registry

> Neue Ereignisquellen melden sich in der `EventTriggerSourceRegistry` an, statt den Auslöser-Code zu ändern.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Ort: `scheduling/domain/entities/event-trigger-source-registry.ts`. Plugins
bringen ihre Quellen selbst mit (Open/Closed).

Quellen mit Sonderform (beide nur lokale Runtime):

- **`webhookReceived`** hat weder Ziel noch Filter, sondern
  `eventConfig.webhook` (`token`, `verification`, `validationParameter`).
- **`shopware`** (Plugin) arbeitet über den Webhook-Empfänger und trägt seine
  Einstellungen in `eventConfig.params` (Ereignis, Verbindung, Status,
  Bestandsgrenze).

## Siehe auch

- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md)
- [Webhooks](../index/webhooks.md) — Geheimnis, Aufruf, Grenzen
- [Shopware: Auslöser über App-Webhooks](./shopware-ausloeser.md)
