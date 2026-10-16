# Datei-Bausteine

> „Datei lesen“ liefert den UTF-8-Inhalt einer konkreten Version; „Datei schreiben“ speichert Text, Datei-, Bild- oder Tabellenwerte als neue Datei oder Version.

Gehört zu: [Aufgabe](../index/aufgabe.md)

**`readFile`:** `value` (`string`, UTF-8-Inhalt der referenzierten Version).

**`writeFile`** nimmt genau einen primären Wert:

- Text → UTF-8.
- `file`/`media` → Bytes über `TeamFileContentReader`; bei Bildern MIME-Type
  und Endung der gespeicherten Version.
- `table` → `.xlsx`.

Primärer Output ist ein `file`- bzw. `media`-Wert, dazu:

| Output | Typ | Bedeutung |
| --- | --- | --- |
| `fileId` | `string` | stabile ID der Datei |
| `versionId` | `string` | ID der geschriebenen Version |
| `displayName` | `string` | Dateiname |
| `contentType` | `string` | MIME-Type |
| `sizeBytes` | `number` | Größe des Inhalts |
| `folderId` | `json` | Ordner-ID oder `null` |
| `isNewFile` | `boolean` | `true` bei neu angelegter Datei |

Heißt der Hauptwert `Bericht`, verwenden Templates `{{Bericht}}` und die
weiteren Werte unter ihren Namen, etwa `{{DateiId}}` oder `{{Dateiname}}`.

Schreiben löst [Datei-Ereignisse](./datei-ereignisse-dispatch.md) aus;
Zielordner und Versionierung stehen in [Dateien](../index/dateien.md).

## Siehe auch

- [Sammlung als Tabelle](./sammlung-als-tabelle.md)
- [Schleifenschutz zur Entwurfszeit](./schleifenschutz-entwurfszeit.md)
