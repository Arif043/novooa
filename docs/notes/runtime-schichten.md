# Runtime-Schichten

> Die Runtime speichert in SQLite; Domain und Use Cases sind datenbank- und frameworkfrei, die Speicher- und Relay-Adapter liegen in der Infrastructure.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```text
Feature Domain
  Entities, Repository-Ports und Use Cases

Feature Infrastructure
  Task Runner und Node Executors
  Genkit-Adapter
  Lokale SQLite- und Dateisystem-Adapter
  Relay-Clients zu den Firebase-Hintergrunddiensten
  HTTP-, Scheduler- und Webhook-Handler
```

Entitäten, Use Cases und Ports kennen weder SQL noch Firebase; SQL-Zeilen und
Firestore-Dokumente der Relays gehören in die Infrastructure.

Ports und Use Cases liegen im Domain-Bereich ihres Features, die Adapter in
dessen Infrastructure-Bereich
([Backend: Feature-First-Struktur](./backend-feature-first.md)).

## Siehe auch

- [Runtime-Adapterübersicht](./runtime-adapteruebersicht.md)
- [Docker-Stack der Runtime](./runtime-docker-stack.md)
