# Sicherheit der Fähigkeiten

> Skills sind Anweisungen von Dritten und damit ein Weg für Prompt-Injection; Skripte darin werden gespeichert, aber nie ausgeführt.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

- Vorschau vor dem Speichern mit Quelle, Dateianzahl und Warnungen; bei
  Katalog-Skills die Partner-Audits.
- `scripts/` wird nie ausgeführt: Das Modell hat nur lesende Werkzeuge
  (`use_skill`, `list_files`, `read_file`).
- Pfade werden gegen `..`, absolute Pfade und Zip-Slip geprüft, Archive gegen
  Zip-Bomben.
- Sicherung und Umzug nur über den Workspace-Transfer (Bereich
  **Fähigkeiten**, alle Ordner mit allen Dateien), weil das Verzeichnis im
  Datenvolume liegt.

## Siehe auch

- [Skills importieren](./skills-import.md)
- [Import/Export](../index/import-export.md)
