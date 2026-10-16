# Datei- und Ordnerablage (0017/0018)

> Jede Datei hat genau eine Ablage, jeder Ordner genau einen Elternbezug; das Team ergibt sich entlang der Elternkette.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Dateien (0017):** entweder `folder_id` (Team abgeleitet) oder
  `root_team_id` ohne Ordner.
- **Ordner (0018):** Unterordner speichern nur ihren Elternbezug,
  Wurzelordner nur `root_team_id`.
- SQL-Trigger verhindern Teamwechsel vorhandener Dateien und Ordner; ein Check
  verhindert Selbstbezüge, rekursive Trigger verhindern Zyklen (auch bei
  Mehrfach-Inserts).
- Ein Ordnerbaum mit Dateien lässt sich nicht direkt löschen; leere
  Unterordner fallen per Kaskade weg. Die Team-Löschkaskade für Metadaten
  bleibt.
- Ordneranlage prüft den Elternbezug in einer Transaktion. Der Datei-Adapter
  prüft die Ablage vor dem Schreiben des Inhalts und erneut in der
  Metadatentransaktion; scheitert diese, entfernt er den neuen Inhalt.
- Versionsmetadaten liegen nur in `file_versions`; die aktuelle Version hängt
  über einen zusammengesetzten Fremdschlüssel an ihrer Datei.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Dateien](../features/dateien.md)
