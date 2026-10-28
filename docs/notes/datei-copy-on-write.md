# Copy-on-Write-Versionen

> Eine Änderung überschreibt nie eine gespeicherte Datei, sondern legt unter derselben `fileId` eine neue Version an.

Gehört zu: [Dateien](../index/dateien.md)

- Erster Upload: Datei plus erste Version.
- Jede Änderung: neue Version unter
  `teams/{teamId}/files/{fileId}/versions/{newVersionId}/{fileName}`; das
  Datei-Dokument aktualisiert nur `currentVersionId`, `storagePath`,
  `sizeBytes`, `contentType`, `updatedAt`.
- Alte Versionen bleiben referenzierbar, bis die
  [Versionsrotation](./datei-versionsrotation.md) sie entfernt.
- Jede Version trägt `createdAt`. Beim Anhängen speichert die Node-Config es
  als `versionCreatedAt`, damit die UI die konkrete Version samt Zeit zeigt.
- Storage erlaubt für Versionen nur `create`, kein Überschreiben.
- Wiederherstellen kopiert den Inhalt einer alten Version in eine neue
  aktuelle Version; die alte bleibt, wie sie ist
  ([Dateiaktionen](./datei-aktionen.md)).

## Siehe auch

- [Datei-Detailansicht](./datei-detailansicht.md)
- [Dateien in Aufgaben anhängen](./datei-anhaenge.md)
