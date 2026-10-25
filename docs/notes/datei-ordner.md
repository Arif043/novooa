# Ordner der Dateiablage

> Ordner sind reine Metadaten; sie ändern die Speicherpfade der Dateien nicht.

Gehört zu: [Dateien](../index/dateien.md)

- Ordner haben `id`, `teamId`, `ownerUid`, `name`, `parentFolderId`,
  `createdAt` und `updatedAt`.
- Dateien speichern optional `folderId`; `null` = oberste Ebene. Unterordner
  nutzen `parentFolderId`, ebenfalls `null` = oberste Ebene.
- Warum nur Metadaten: Die Copy-on-Write-Struktur der Versionen bleibt
  stabil, Verschieben kopiert keine Inhalte.
- Speicherung: [Datei- und Ordnerablage (0017/0018)](./sqlite-dateiablage-normalisiert.md).

## Siehe auch

- [Dateien-Seite](./dateien-seite.md)
- [Copy-on-Write-Versionen](./datei-copy-on-write.md)
