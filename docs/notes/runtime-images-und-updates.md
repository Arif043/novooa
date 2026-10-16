# Images, Updates und Neustarts der Runtime

> Ausgelieferte Stacks referenzieren feste novooa-Versionen, sichern SQLite vor jedem Update und starten von selbst neu.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Das Entwicklungs-Compose baut die Images aus dem Checkout. Die
  ausgelieferte Desktop-App referenziert konkrete Versionen, **nie `latest`**.
- Vor einem Update legt `novooa-runtime` ein SQLite-Backup an (noch nicht
  umgesetzt).
- Nur die Runtime führt Migrationen aus (idempotent) und meldet den
  Health-Status.
- Runtime und ML-Dienst laufen mit `restart: unless-stopped`, damit Zeitpläne
  und gepufferte Relay-Ereignisse auch ohne geöffnete Desktop-App verarbeitet
  werden.

## Siehe auch

- [SQLite-Migrationen](./sqlite-migrationen.md)
- [Docker-Stack der Runtime](./runtime-docker-stack.md)
