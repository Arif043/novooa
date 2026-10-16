# Dateien in Aufgaben anhängen

> Bausteine mit `FileAttachmentSupport` speichern `NodeAttachment`s, die immer auf eine konkrete Dateiversion zeigen.

Gehört zu: [Dateien](../index/dateien.md)

- Die UI lädt auswählbare Dateien über `WatchTeamFiles` aus dem aktuellen
  Team und referenziert beim Anhängen die aktuelle Version.
- „Datei lesen“ nutzt dieselbe Auswahl, speichert aber genau eine Version als
  `NodeAttachment`.
- Bei der Ausführung landen Anhänge im
  [temporären Workspace](./anhaenge-workspace.md): Prompt read-only über die
  Filesystem-Middleware, Script über `list_files()` und `read_file(name)`.

## Siehe auch

- [Datei-Bausteine](./datei-bausteine.md)
- [Versionsrotation](./datei-versionsrotation.md)
