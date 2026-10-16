# Fastify-Plugins der Runtime

> Jedes Feature registriert seine Routen als Fastify-5-Plugin mit seinen stabilen Abhängigkeiten als Plugin-Optionen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Routing, Pfadparameter, JSON-Parsing, Body-Limit (1 MiB),
  Schema-Validierung und Fehlerantworten liegen bei Fastify.
- Plugins heißen `local-<feature>-routes.ts` (z. B. `dataRoutes`,
  `fileResourceRoutes`) und werden beim Start einmal mit Stores und
  Relay-Clients registriert (`local-runtime-routes.ts`,
  `local-runtime-route-services.ts`). Use Cases bleiben davon unabhängig.
- `@fastify/cors` erzeugt CORS-Header und Preflights; fremde Herkünfte werden
  auch beim Preflight abgewiesen.
- `@fastify/static` liefert das Web-Build mit SPA-Fallback aus, ohne API-Pfade
  zu überdecken.
- ONNX- und ZIP-Uploads nutzen native Streaming-Content-Parser.
- JSON-Anfragen brauchen `Content-Type: application/json`; `204` hat keinen Body.
- Healthcheck und Web-Build liegen außerhalb der API-Zugriffsprüfung;
  WebSockets sind über Einmaltickets geschützt.
- Beim Shutdown schließen erst WebSockets und Fastify, dann Worker und
  Datenbank.

## Siehe auch

- [Route-Schemas mit TypeBox](./runtime-route-schemas.md)
- [Anfrage-Pipeline: Lizenz → Session → Route](./runtime-anfrage-pipeline.md)
