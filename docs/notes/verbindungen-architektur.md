# Architektur der Verbindungen

> Verbindungen sind die ausgehende Hälfte der Schicht für externe Systeme; Systeme mit Besonderheiten bekommen später dünne Adapter darauf.

Gehört zu: [Verbindungen](../index/verbindungen.md)

| Schicht | Ort |
| --- | --- |
| Verbindung, Eingabeprüfung, Ports | `functions/src/features/connections/domain/` |
| SQLite-Store, Token-Anbieter, Anmeldung, HTTP-Client, Routen | `…/connections/infrastructure/local/` |
| Executor | `task_execution/domain/executors/http-request-node-executor.ts` |
| Dienst für Executoren | `TaskRunServices.outboundHttpClient` |
| Log-Maskierung | `structured-log-format-utils.ts` (`redactedConfig`) |
| Client: Feature | `lib/features/connections/` (Einstellungen-Tab „Verbindungen“) |
| Client: Baustein | `http_request_node_config.dart`, `http_request_widget.dart` |

Warum allgemein: Aufgaben sollen die HTTP-API beliebiger Systeme (Shop, ERP,
Mail-Dienst) nutzen, ohne dass je System neuer Code entsteht. Eingehende
Aufrufe regeln die [Webhooks](../index/webhooks.md).

## Siehe auch

- [Integrations-Plugins](./integrations-plugins.md)
- [Verbindung](./verbindung.md)
