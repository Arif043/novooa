# Google-Drive-Bausteine

> Das Plugin `google_drive` bringt „In Google Drive speichern“ und „Aus Google Drive lesen“; beide laufen in der Runtime und rufen die Drive-API direkt auf.

Gehört zu: [Google Drive](../index/google-drive.md)

Beide teilen sich das Primitive `googleDrive` (`config.action`, `accountId`,
`params`), wie die [Shopware-Aktionen](./shopware-plugin.md).

**„In Google Drive speichern“** (`upload`):

- Eingaben: Konto, Zielordner (freigegebener Ordner oder „Meine Ablage“),
  Dateiname (Template), Inhalt (Template).
- Der Inhalt wird wie bei [„Datei schreiben“](./datei-bausteine.md)
  aufgelöst (`workflowValueContent`): Text als Text, Team-Dateien und Bilder
  mit ihren Bytes und ihrem Typ, Tabellen als XLSX.
- Ausgaben: `value` (`string`, Link zum Öffnen), `driveFileId`, `name`,
  `mimeType` (`string`), `sizeBytes` (`number`).

**„Aus Google Drive lesen“** (`read`):

- Eingaben: Konto und Datei, entweder eine freigegebene Datei oder eine
  Datei-ID aus einem vorherigen Baustein (z. B. `{{driveFileId}}`).
- Google-Dokumente, -Präsentationen und -Zeichnungen kommen als PDF,
  Tabellen als XLSX; andere Google-Formate (z. B. Formulare) melden einen
  Fehler.
- Die Datei wird als neue Team-Datei abgelegt; folgende Bausteine nutzen sie
  wie jede andere Datei.
- Ausgaben: `value` (`file`), `driveFileId`, `name`, `mimeType`.

Fehler:

- Bei 401 von Google wird einmal mit frischem Token wiederholt.
- 403 und 404 melden „nicht gefunden oder nicht freigegeben“ und verweisen
  auf „Weitere Dateien freigeben“.

Ort: `functions/src/features/integrations/google_drive/`,
`lib/features/integrations/google_drive/`.

## Siehe auch

- [Scope `drive.file`](./google-drive-scope.md)
- [Bausteine von Plugins](./plugin-bausteine.md)
