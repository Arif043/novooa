# Feature: Import/Export

## Zweck

In der lokalen Runtime (Standalone) können Nutzer:innen ausgewählte
Datenbestände als ZIP-Datei sichern und wieder einspielen — etwa als Backup
oder um einen Arbeitsbereich auf eine andere Installation zu übertragen. Der
Tab **„Import/Export“** liegt in den Runtime-Einstellungen. Die
Firebase-Variante hat dieses Feature nicht.

## Verantwortlichkeiten

- Export der ausgewählten Bereiche als ZIP-Datei (Download über den
  Speichern-Dialog bzw. im Web als Browser-Download).
- Import in zwei Schritten: Datei hochladen und prüfen (Vorschau mit Anzahl je
  Bereich), danach die zu übernehmenden Bereiche wählen und bestätigen.
- Zusammenführen statt Ersetzen: Einträge werden per ID eingefügt, gleiche IDs
  werden mit dem Stand aus dem Export überschrieben, nichts wird gelöscht.
- Team-gebundene Dateipfade (`teams/{teamId}/files/...`) und Verweise darauf in
  Aufgaben werden auf den Ziel-Arbeitsbereich umgeschrieben.

## Bereiche

| Bereich | Inhalt | Anzahl im Manifest |
| --- | --- | --- |
| `files` – Dateien & Ordner | Ordner, Dateien, alle Versionen samt Bytes | Dateien |
| `data` – Daten-Collections | Datensammlungen und Datensätze | Datensätze |
| `knowledge` – Wissensbasis | Notizen inkl. Links | Notizen |
| `skills` – Fähigkeiten | Skill-Ordner mit allen Dateien (`SKILL.md`, `scripts/`, `references/`, `assets/`) | Skills |
| `tasks` – Aufgaben | Aufgabendefinitionen (Graph) | Aufgaben |

**Nie enthalten:** Trigger (können an OAuth-Connectoren gebunden sein),
Ausführungen/Runs, Aktivitäten, Anwendungsprotokolle, API-Schlüssel,
Zugangsdaten und Sessions.

## Archivformat (Version 1)

```text
manifest.json         { format: "novooa-export", version: 1, exportedAt,
                        sourceTeamId, categories, counts }
data/files.json       { folders, files, versions }
data/data.json        { collections, documents }
data/knowledge.json   { notes }
data/skills.json      { skills: [{ name, files: [{ path }] }] }
data/tasks.json       { tasks }
blobs/<storagePath>   Bytes je Dateiversion
blobs/skills/<name>/<pfad>   Bytes je Datei eines Skills
```

Zeilen werden als camelCase-DTOs ohne `teamId` geschrieben. Beim Import prüft
die Runtime jede Datei per Schema (zod); Pfade außerhalb des Quellteams oder
mit `..` werden abgelehnt.

## Ablauf und Garantien

- **Export:** `POST /v1/transfer/export` mit `{categories}` streamt
  `application/zip`. Dateiversionen, deren Bytes auf der Platte fehlen, werden
  ausgelassen.
- **Import prüfen:** `POST /v1/transfer/imports` (Body `application/zip`,
  max. 4 GiB) liefert `{importId, manifest}`. Der Upload liegt 30 Minuten unter
  `<runtimeRoot>/transfer-imports/`.
- **Import übernehmen:** `POST /v1/transfer/imports/{id}/apply` mit
  `{categories}` liefert `{imported}`. Zuerst werden alle Bereiche gelesen und
  geprüft und die Datei-Bytes kopiert, danach werden alle Zeilen in **einer**
  SQLite-Transaktion geschrieben. Schlägt ein Bereich fehl, bleibt der
  Datenbestand unverändert und neu kopierte Dateien werden entfernt.
- **Verwerfen:** `DELETE /v1/transfer/imports/{id}`.
- **Fähigkeiten:** Der Skills-Ordner gehört der Anwendung und ist nicht team-gebunden. Ein gleichnamiger Skill im
  Ziel wird **vollständig ersetzt** (auch Dateien, die es im Export nicht gibt, entfallen); andere Skills bleiben
  unberührt, nichts wird gelöscht. Scheitert der Import in einem späteren Bereich, wird der alte Stand der ersetzten
  Skills wiederhergestellt und neu angelegte werden entfernt. Pfade mit `..`, absolute Pfade, fehlende `SKILL.md`,
  doppelte Namen und Überschreitungen der Skill-Grenzen (200 Dateien, 10 MB) machen den Export ungültig. Blob-Einträge
  beginnen mit `blobs/`, damit `.json`-Dateien innerhalb eines Skills nicht als Archiv-JSON gelesen werden.
- Gleichnamige Datensammlung im Ziel: Die Datensätze landen in der vorhandenen
  Sammlung (Namen sind pro Team eindeutig).

## Architektur

- Backend: `functions/src/features/workspace_transfer/`. `TransferSection` ist
  ein Strategy-Port je Bereich, Use Cases `ExportWorkspace`,
  `InspectWorkspaceImport`, `ImportWorkspace`. ZIP-Adapter auf Basis von `fflate`.
- Client: `lib/features/workspace_transfer/`. Zwei Cubits
  (`WorkspaceExportCubit`, `WorkspaceImportCubit`), Dateidialoge über
  `TransferFileGateway` (file_picker), Binärübertragung über
  `WorkspaceBinaryClient`.

## Offene Fragen

- Aufgaben können auf Kommunikationskanäle, Sprachmodelle oder Mitarbeiter
  verweisen, die nicht exportiert werden. Diese Verweise bleiben unverändert
  und können im Ziel ins Leere zeigen.
- Der Client hält Export und Import vollständig im Speicher. Für sehr große
  Datei-Bestände wäre Streaming im Client nötig.

## Verwandt

- [`dateien.md`](./dateien.md), [`daten.md`](./daten.md),
  [`wissensbasis.md`](./wissensbasis.md), [`aufgabe.md`](./aufgabe.md)
- [`../local-runtime.md`](../local-runtime.md)
- [`../architecture.md`](../architecture.md)
