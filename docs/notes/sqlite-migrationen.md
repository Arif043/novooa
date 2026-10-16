# SQLite-Migrationen

> Drizzle Kit erzeugt Migrationen aus den Models; die Runtime führt sie beim Start mit dem nativen Migrator aus, ohne Schema-Push.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Nach einer Model-Änderung: `npm --prefix functions run db:generate`
  (Migration samt Snapshot; Konfiguration in `drizzle.config.ts`).
- Manuell anwenden: `DB_FILE_NAME=file:/absoluter/pfad/novooa.sqlite npm
  --prefix functions run db:migrate`.
- Historie in `__drizzle_migrations`. Die alten Migrationen und
  `schema_migrations` sind abgelöst; eine bestehende Datenbank wird weder
  gelöscht noch zurückgesetzt.

Die Initialmigration
[`0000_initial_runtime.sql`](../../functions/drizzle/0000_initial_runtime.sql)
legt u. a. an: `teams`, `team_members`, `tasks`, `task_runs`, `activities`,
`application_logs`, `task_triggers`, `communication_channels`,
`knowledge_notes`, `files`, `file_versions`, `file_folders`,
`document_collections`, `documents`, `model_catalog`, Provider-Verbindungen,
Sprachmodellprofile, `language_model_secrets` sowie die Jobqueue.

Normalisierende Migrationen brechen bei widersprüchlichen Daten atomar ab,
statt Daten zu raten.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [SQLite-Anbindung mit Drizzle](./sqlite-drizzle-anbindung.md)
