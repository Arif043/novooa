# Architektur der Webhooks

> Webhooks sind ein eigenes Routen-Plugin neben der API mit eigener Lizenzprüfung, Rohbody-Parser und Fehler-Handler; Plugins hängen eigene Interpreter an.

Gehört zu: [Webhooks](../index/webhooks.md)

- **Routen-Plugin** `webhookRoutes`, registriert in `runtimeRoutes` neben
  `localRuntimeApi`. Warum getrennt: Die API-Hooks verlangen Sitzung und
  Lizenz; ein externes System hat keine Sitzung. Der Parser liest alle
  Inhaltstypen als `Buffer`, auch JSON (für die Signatur).
- **Domain** (`features/webhooks/domain`): `ReceiveWebhook` (Ablauf),
  `verify-webhook-signature` (reine Funktion), `webhook-event` (Ereignis,
  Kopfzeilenfilter, Body-Auswertung). Zugang zum Arbeitsbereich über
  `workspaceContext.webhooks`, wie `fileEvents`.
- **Konfiguration** in `scheduling`: `EventTriggerConfig.webhook` (`token`,
  `verification`, `validationParameter`) in `task_triggers.event_config_json`;
  die `EventTriggerSourceRegistry` vergibt das Token serverseitig (`prepare`).
- **Interpreter anderer Quellen** (`WebhookInterpreter`,
  `webhooks/domain/entities/webhook-interpreter.ts`): Eine Quelle mit
  `usesWebhook` bekommt Token und Adresse; nach Token- und Signaturprüfung
  liefert ihr Interpreter null bis zehn Läufe (Kontexttext, Ereignis). Plugins
  bringen Quelle und Interpreter mit (`IntegrationPlugin.eventTriggers`,
  Beispiel Shopware); quellspezifische Einstellungen in
  `EventTriggerConfig.params`, geprüft vom Plugin (`problem`).
- **Geheimnis:** verschlüsselt in `language_model_secrets` mit
  `secret_ref = webhook/<team>/<trigger>` (gleiche Rotation wie Verbindungen),
  nie in der Konfiguration, nie ausgeliefert, mit dem Auslöser gelöscht.
- **Routen:** `POST /v1/task-triggers` (legt Token und Geheimnis an),
  `POST /v1/task-triggers/:id/webhook-token` (Token erneuern).
- **Begrenzung:** Token-Bucket des Skills-Relays im Speicher
  (`InMemoryBucketStateStore`); Neustart oder Arbeitsbereichswechsel setzt
  zurück.

## Siehe auch

- [Ablauf eines Webhook-Aufrufs](./webhook-aufruf.md)
- [Shopware-Auslöser](./shopware-ausloeser.md)
- [Ereignisquellen-Registry](./ereignisquellen-registry.md)
