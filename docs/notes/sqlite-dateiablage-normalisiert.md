# Datei- und Ordnerablage (0017/0018)

> Jede Datei hat genau eine Ablage, jeder Ordner genau einen Elternbezug; das Team ergibt sich entlang der Elternkette.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md) · [Dateien](../index/dateien.md)

- **Dateien (0017):** entweder `folder_id` (Team abgeleitet) oder
  `root_team_id` ohne Ordner.
- **Ordner (0018):** Unterordner speichern nur ihren Elternbezug,
  Wurzelordner nur `root_team_id`.
- SQL-Trigger verhindern Teamwechsel vorhandener Dateien und Ordner (auch
  das Umhängen ganzer Unterbäume); ein Wechsel zwischen oberster Ebene und
  Ordnern desselben Teams ist erlaubt. Ein Check verhindert Selbstbezüge,
  rekursive Trigger verhindern Zyklen, auch bei Mehrfach-Inserts und direkten
  SQL-Schreibzugriffen (rekursive Abfragen in der Trigger-Unterabfrage, siehe
  [SQLite-Trigger](https://www.sqlite.org/lang_createtrigger.html)).
- Ein Ordnerbaum mit Dateien lässt sich nicht direkt löschen; leere
  Unterordner fallen per Kaskade weg. Dateien vorher über den Datei-Adapter
  löschen oder umordnen — die SQLite-Kaskade entfernt keine Inhalte auf dem
  Dateisystem.
- Beim Löschen eines Teams entfernt ein Trigger zuerst dessen Dateien auf allen
  Ordnerebenen; Wurzeldateien, Ordner und Versionen folgen über Fremdschlüssel.
- Export ordnet das Team über sein Manifest zu; Migration und Import/Export
  erhalten Versionen samt Rotationsreihenfolge.
- Ordneranlage prüft den Elternbezug in einer Transaktion. Der Datei-Adapter
  prüft die Ablage vor dem Schreiben des Inhalts und erneut in der
  Metadatentransaktion; scheitert diese, entfernt er den neuen Inhalt.
- Versionsmetadaten liegen nur in `file_versions`; die aktuelle Version hängt
  über einen zusammengesetzten Fremdschlüssel an ihrer Datei.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Dateien](../index/dateien.md)
