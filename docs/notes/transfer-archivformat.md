# Archivformat von Import/Export

> Archivversion 2: ein Manifest, je Bereich eine JSON-Datei mit camelCase-DTOs ohne `teamId` und die Bytes unter `blobs/`.

Gehört zu: [Import/Export](../index/import-export.md)

```text
manifest.json         { format: "novooa-export", version: 2, exportedAt,
                        sourceTeamId, categories, counts }
data/files.json       { folders, files, versions }
data/data.json        { collections, documents }
data/knowledge.json   { notes }
data/skills.json      { skills: [{ name, files: [{ path }] }] }
data/employees.json   { employees: [{ id, name, constraint, skills, createdAt, updatedAt }] }
data/tasks.json       { tasks }
blobs/<storagePath>   Bytes je Dateiversion
blobs/skills/<name>/<pfad>   Bytes je Datei eines Skills
```

- Jede Datei wird beim Import per Schema (zod) geprüft; Pfade außerhalb des
  Quellteams oder mit `..` werden abgelehnt.
- Datei-Einträge: Identität, Besitzer, Name, Ordner, Zeitstempel,
  `currentVersionId`. Speicherpfad, Typ und Größe nur an Versionen.
- Blob-Einträge beginnen mit `blobs/`, damit `.json`-Dateien in Skills nicht
  als Archiv-JSON gelesen werden.
- Version 1 wird nicht mehr unterstützt; keine Übersetzung alter Formate.

## Siehe auch

- [Bereiche von Import/Export](./transfer-bereiche.md)
- [Dateiversionen in SQLite (0009)](./sqlite-dateiversionen-normalisiert.md)
