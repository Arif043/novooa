# Google-Drive-Bausteine

> Das Plugin `google_drive` bringt „In Google Drive speichern“, „Aus Google Drive lesen“ und „In Google Drive suchen“; alle laufen in der Runtime und rufen die Drive-API direkt auf.

Gehört zu: [Google Drive](../index/google-drive.md)

Alle teilen sich das Primitive `googleDrive` (`config.action`, `accountId`,
`params`), wie die [Shopware-Aktionen](./shopware-plugin.md). Wechselt man im
Baustein das Konto, werden Ordner und eine aus der Liste gewählte Datei
geleert, weil sie zum alten Konto gehören; eine Datei-ID als Template bleibt.

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

**„In Google Drive suchen“** (`search`):

- Eingaben: Konto, Ort („Überall“, „Meine Ablage“ = `root` oder ein
  freigegebener Ordner), „Name enthält“ (Template), Höchstanzahl (1–100,
  ohne Angabe 25).
- Neueste Dateien zuerst, Papierkorb ausgenommen. Wegen
  [`drive.file`](./google-drive-scope.md) findet die Suche nur Dateien, die
  novooa angelegt hat oder die freigegeben wurden.
- Ausgaben: `value` (`json`, Array aus `{id, name, mimeType, link,
  sizeBytes, modifiedAt}`), `count` (`number`), `found` (`boolean`).
- Beispiel: Suchen → [„Für jedes Element“](./foreach-baustein.md) →
  „Aus Google Drive lesen“ mit der Datei-ID `{{iteration.value.id}}`.

Fehler:

- Bei 401 von Google wird einmal mit frischem Token wiederholt.
- 404 meldet „nicht gefunden oder nicht freigegeben“ und verweist auf
  „Weitere Dateien freigeben“.
- Ein voller Drive-Speicher (`storageQuotaExceeded`) wird als solcher
  gemeldet; andere Ablehnungen nennen Status und Googles Begründung.

Ort: `functions/src/features/integrations/google_drive/`,
`lib/features/integrations/google_drive/`.

## Siehe auch

- [Scope `drive.file`](./google-drive-scope.md)
- [Bausteine von Plugins](./plugin-bausteine.md)
