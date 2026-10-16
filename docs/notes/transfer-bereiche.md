# Bereiche von Import/Export

> Standalone sichert und überträgt Dateien, Daten, Wissensbasis, Fähigkeiten, Mitarbeiter und Aufgaben als ZIP; Auslöser, Läufe und Zugangsdaten sind nie dabei.

Gehört zu: [Import/Export](../index/import-export.md)

Tab **„Import/Export“** in den Runtime-Einstellungen; die Cloud hat das
Feature nicht.

| Bereich | Inhalt | Anzahl im Manifest |
| --- | --- | --- |
| `files` | Ordner, Dateien, alle Versionen samt Bytes | Dateien |
| `data` | Datensammlungen und Datensätze | Datensätze |
| `knowledge` | Notizen und Metadaten; Links nach Import abgeleitet | Notizen |
| `skills` | Skill-Ordner mit allen Dateien | Skills |
| `employees` | Rahmenbedingung und Skill-Namen | Mitarbeiter |
| `tasks` | Aufgabendefinitionen (Graph) | Aufgaben |

**Nie enthalten:** Auslöser (können an OAuth-Connectoren hängen), Läufe,
Aktivitäten, Anwendungsprotokolle, API-Schlüssel, Zugangsdaten, Sitzungen,
[Verbindungen](./verbindung.md).

- Zusammenführen statt Ersetzen: per ID einfügen, gleiche IDs mit dem
  Exportstand überschreiben, nichts löschen.
- Team-gebundene Dateipfade (`teams/{teamId}/files/...`) und Verweise darauf in
  Aufgaben werden auf den Ziel-Arbeitsbereich umgeschrieben.
- Verweise auf Kanäle, Sprachmodelle oder Verbindungen bleiben unverändert und
  können im Ziel ins Leere zeigen (keine Prüfung beim Import).

## Siehe auch

- [Archivformat von Import/Export](./transfer-archivformat.md)
- [Ablauf und Garantien von Import/Export](./transfer-ablauf.md)
