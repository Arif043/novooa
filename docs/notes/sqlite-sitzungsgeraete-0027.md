# Geräte der Sitzungen (0027)

> Migration 0027 legt `runtime_sessions` neu an, mit öffentlicher Kennung, Geräteangaben und letzter Nutzung; bestehende Sitzungen bleiben gültig.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Neue Spalten: `id` (zufällig, eindeutiger Index, zum einzelnen Abmelden;
  nicht das Token), `device_app`, `device_os`, `device_browser`,
  `last_used_at`.
- SQLite kann keine NOT-NULL-Spalte ohne Default ergänzen; deshalb neue Tabelle,
  Zeilen kopieren, alte löschen. drizzle-kit erzeugte nur `ADD COLUMN`; die
  Migration ist von Hand geschrieben.
- Bestandszeilen: `id` aus `randomblob(16)`, Gerät `unknown`, `last_used_at`
  = `expires_at` − 7 Tage, `created_at` als ISO-Zeit. Niemand wird
  abgemeldet. Test: `multi-user-migration.test.ts` (Stand 0026 → 0027).

## Siehe auch

- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [SQLite-Migrationen](./sqlite-migrationen.md)
