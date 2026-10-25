# Dateien-Seite

> Ohne Dateien zeigt „Dateien“ einen zentrierten Einstieg, danach eine Kartenliste im Stil des Zeitplans mit „Neuer Ordner“ und „Datei hochladen“ in der Kopfzeile.

Gehört zu: [Dateien](../index/dateien.md)

Code: `lib/features/files/presentation/pages/files_page.dart`.

- **Leer** (`FilesState.isInitial`): `FilesInitialState` nach dem
  [Muster für leere Zustände](./leerer-zustand-muster.md); Upload über
  `pickUploadFile`.
- **Mit Inhalt:** [Luminous-Seitenstil](./luminous-seitenstil.md) — Titel
  links, `FilesActionBar` rechts im umbrechenden `Wrap`, Untertitel;
  Brotkrumen nur innerhalb eines Ordners (`FilesHeader`). Einträge sind Karten
  (`FilesItemCard`) mit 12 px Abstand; Herunterziehen aktualisiert.
- Ein leerer Unterordner zeigt nur einen Hinweis in der Liste.
- Löschen mit Bestätigung am Eintrag; `DELETE /v1/files/:fileId` entfernt Metadaten, alle Versionen und Inhalte
  und löst ein [Datei-Ereignis](./datei-ereignisse-dispatch.md) aus.

## Siehe auch

- [Ordner der Dateiablage](./datei-ordner.md)
- [Datei-Detailansicht](./datei-detailansicht.md)
- [Zeitplan-Seite](./zeitplan-seite.md)
