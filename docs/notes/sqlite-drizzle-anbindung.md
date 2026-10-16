# SQLite-Anbindung mit Drizzle

> SQLite ist der Standard für strukturierte Standalone-Daten; Repositories nutzen Drizzle ORM direkt, ohne eigenen Treiber oder Wrapper.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Warum SQLite: kein Server, transaktional, passend für Aufgaben, Runs,
Aktivitäten, Auslöser, Teams, Kanäle, Wissensbasis-Metadaten und
Modellkataloge.

- Nach der [Drizzle-SQLite-Anleitung](https://orm.drizzle.team/docs/get-started/sqlite-new):
  `@libsql/client` öffnet die Datei, `drizzle({client, schema})` erzeugt die
  Datenbank. Kein SQLite-Proxy, kein `get/all/run`-Wrapper.
- Tabellen in [`functions/src/db/models`](../../functions/src/db/models)
  (`core`, `integration`, `resources`; 28 Tabellen mit Constraints, Indizes
  und `$inferSelect`/`$inferInsert`), exportiert über
  [`schema.ts`](../../functions/src/db/schema.ts). Repository-Verträge bleiben
  frameworkfrei.
- Repositories nutzen `select`, `insert`, `update`, `delete`, Joins und
  Upserts; `sql` nur für SQLite-Ausdrücke und komplexe Abfragen.
- Transaktionen explizit über `tx`; verschachtelte über Savepoints.
- Job-Leases werden atomar mit `UPDATE … RETURNING` beansprucht.
- `openLocalRuntimeDatabase` aktiviert Fremdschlüssel, WAL und Busy-Timeout.

## Siehe auch

- [SQLite-Migrationen](./sqlite-migrationen.md)
- [SQLite-Normalisierung](../architecture/sqlite-normalisierung.md) — Prüfstand aller Tabellen
