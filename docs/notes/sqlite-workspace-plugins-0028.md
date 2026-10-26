# Plugins je Arbeitsbereich (0028)

> Migration 0028 legt `workspace_plugins` an: eine Zeile je aktiviertem Plugin und Arbeitsbereich.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Spalten: `team_id` (Kaskade an `teams`), `plugin_id`, `enabled_at`,
  `enabled_by_uid`; Primärschlüssel `(team_id, plugin_id)`.
- Aktiv heißt: Es gibt eine Zeile. Erneutes Aktivieren behält den ersten
  Zeitpunkt; Deaktivieren löscht die Zeile.
- Reine Neuanlage: Nach dem Update sind alle Plugins aus
  ([Plugins aktivieren](./plugin-aktivierung.md)).

## Siehe auch

- [SQLite-Migrationen](./sqlite-migrationen.md)
