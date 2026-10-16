# Runtime-Schichten

> Standalone nutzt SQLite, Cloud nutzt Firestore; beide teilen Domain und Use Cases und unterscheiden sich nur in den Adaptern.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

```text
Feature Domain
  Entities, Repository-Ports und Use Cases

Feature Infrastructure
  Task Runner und Node Executors
  Firebase-, Genkit- und Twilio-Adapter
  Lokale SQLite- und Dateisystem-Adapter
  Callable-, Scheduler- und Webhook-Handler
```

Die fünf verbindlichen Regeln (gemeinsame Modelle, getrennte Speicheradapter,
maßgebliche Datenquelle, Konsistenz, Vertragstests) stehen in
[SQLite und Firebase: fünf Regeln](./sqlite-und-firebase-regeln.md).

Ports und Use Cases liegen im Domain-Bereich ihres Features, Cloud- und
Local-Adapter austauschbar in dessen Infrastructure-Bereich
([Backend: Feature-First-Struktur](./backend-feature-first.md)).

## Siehe auch

- [Runtime-Adapterübersicht](./runtime-adapteruebersicht.md)
- [Docker-Stack der Runtime](./runtime-docker-stack.md)
