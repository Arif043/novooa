# Versionsrotation

> Je Datei bleiben nur die letzten N Versionen; die aktuelle bleibt immer, ältere werden samt Inhalt gelöscht.

Gehört zu: [Dateien](../index/dateien.md)

`SQLiteTeamFileStore` rotiert nach jedem Schreiben. Limit 1–1000 (Standard
10) je Arbeitsbereich in `workspace_file_settings`; UI unter Einstellungen →
Allgemein → „Dateiversionen“ (`GET`/`PUT /v1/file-settings`). Eine Änderung
greift beim nächsten Schreiben und entfernt dann auch vorhandene
Überhangversionen.

Folge: Referenzen auf rotierte Versionen (etwa ein `NodeAttachment` mit
konkreter `versionId`) lassen sich nicht mehr laden.

## Siehe auch

- [Copy-on-Write-Versionen](./datei-copy-on-write.md)
- [Dateien in Aufgaben anhängen](./datei-anhaenge.md)
