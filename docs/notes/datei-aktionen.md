# Dateiaktionen

> Umbenennen und Verschieben ändern nur die Datei, Kopieren legt eine neue Datei an, Wiederherstellen eine neue Version — gespeicherte Versionen bleiben unangetastet.

Gehört zu: [Dateien](../index/dateien.md)

| Aktion | Route | Wirkung | Ereignis |
| --- | --- | --- | --- |
| Umbenennen, Verschieben | `PATCH /v1/files/:fileId` `{name?, folderId?}` | `files.display_name` bzw. Ort; Versionen und Speicherpfade bleiben. `folderId: null` = oberste Ebene, fehlend = Ordner bleibt | keins |
| Kopieren | `POST /v1/files/:fileId/copy` `{name?, folderId?}` | Neue Datei mit dem Inhalt der aktuellen Version; Standard sind Name und Ordner der Quelle | `fileCreated` |
| Wiederherstellen | `POST /v1/files/:fileId/versions/:versionId/restore` | Der Inhalt der alten Version wird eine neue aktuelle Version | `fileVersionCreated` |
| Neue Version hochladen, Bild bearbeiten, Text speichern | `POST /v1/files/:fileId/versions` | Neue Version; der Dateiname bleibt | `fileVersionCreated` |
| Herunterladen | `GET …/versions/:versionId/content` | Speichern-Dialog am Desktop, Download im Web, unter dem heutigen Namen | – |
| Löschen | `DELETE /v1/files/:fileId` | Datei samt allen Versionen | `fileDeleted` |

- **Namen:** wie beim Hochladen ohne Pfadanteile, höchstens 255 Zeichen
  (Client: `FileName`). Ein Name, den eine andere Datei im Zielordner trägt,
  ergibt `409` — „Datei schreiben“ findet Dateien der obersten Ebene über
  den Namen, doppelte Namen wären dort mehrdeutig.
- **Kopie:** Der Client schickt den Wunschnamen in der App-Sprache
  (`Bericht (Kopie).pdf`), die Runtime macht ihn eindeutig
  (`Bericht (Kopie) (2).pdf`, `uniqueFileNameFor`). Die Quelle bekommt keine
  Version; die Kopie hat nur die aktuelle.
- Kopieren und Wiederherstellen laufen über `writeTeamFile` und damit über
  [Versionsrotation](./datei-versionsrotation.md) und
  [Datei-Ereignisse](./datei-ereignisse-dispatch.md); sie können Aufgaben
  auslösen. Umbenennen und Verschieben tun das nicht.
- Umsetzung: `SQLiteTeamFileMutations`, Routen in
  `local-file-mutation-routes.ts`; Client `LocalFileMutationRequests`,
  `FileActionsCubit`.

## Siehe auch

- [Datei-Detailansicht](./datei-detailansicht.md)
- [Copy-on-Write-Versionen](./datei-copy-on-write.md)
