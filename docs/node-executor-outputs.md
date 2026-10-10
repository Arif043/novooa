# Node-Executor-Outputs

> Referenz fuer die Resultate der Backend-Executoren unter
> `functions/src/features/task_execution/infrastructure/genkit/executors/`.

## Ergebnisvertrag

Jeder Executor liefert ein `NodeExecutionResult` mit einem `outputs`-Objekt.
Ein Output hat einen der Typen `string`, `datetime`, `number`, `boolean`,
`json`, `file`, `media`, `audio` oder `table`. Ein ausgefuehrter Baustein mit einem
fachlichen Rückgabewert stellt ihn unter `value` bereit. Reine
Seiteneffekt-Bausteine ohne fachlichen Rückgabewert (aktuell:
`notificationSend`) liefern ein leeres `outputs`-Objekt und haben im Builder
keine benannten Werte (`WorkflowPrimitive.hasNoOutput`, ausgewertet von
`outputKeysOf` in `workflow_node_outputs.dart`). Kanten bestimmen weiterhin nur Reihenfolge
und Verzweigung; ein Executor erhaelt die `value`-Outputs seiner direkten
Vorgaenger, nicht mehr den letzten Textwert eines Runs.

`media`, `audio` und `file` enthalten eine fachliche Referenz mit `fileId`, `versionId`,
`displayName`, `contentType` und `sizeBytes`. Der konkrete Speicherort bleibt
innerhalb der Dateiinfrastruktur; erst der konsumierende Executor liest die
referenzierte Version.

**Alle Werte sind flach benannt.** Es gibt einen einzigen, graph-weiten
Namensraum (`flatOutputsFor` in `template-expression-resolver.ts`):

- Jeder Baustein speichert seine benannten Werte als Liste
  `outputs: [{key, name, showOnCanvas}]` (`WorkflowOutput`). `key` ist der
  Schlüssel aus der Tabelle unten (`value` für den Hauptwert, sonst z. B.
  `found`), `name` der Name in Vorlagen (`{{Datensatz}}`, `{{Gefunden}}`).
  Einen separaten `outputName` gibt es nicht mehr.
- `showOnCanvas` entscheidet nur, ob der Wert als Chip auf der Leinwand
  steht. Im Panel stehen immer alle Werte; dort lassen sie sich umbenennen
  und per Pin-Symbol auf die Leinwand holen. Standard: Hauptwert an, übrige
  aus.
- Der Builder vergibt die Namen beim Anlegen lokalisiert und großgeschrieben,
  ab 2 nummeriert („Gefunden“, „Gefunden2“), und hält sie eindeutig. Ein
  Wert ohne Eintrag in `outputs` ist per Template nicht erreichbar; auch die
  Knoten-ID dient nicht als Ersatzname.
- Die Schlüssel der Tabelle sind nur der technische Vertrag zwischen
  Executor und Builder, keine Namen für Nutzer:innen. Eine Adressierung über
  den Knotennamen (`{{Datensatz.found}}`, `{{Datensatz.value}}`) gibt es
  nicht. Ein Punkt-Pfad führt nur in den JSON-Inhalt eines Werts
  (`{{antwort.name}}`).
- Bausteine mit Feldern (strukturierte Prompt-Ausgabe, Dialogeingabe,
  Script mit `workflow_output`) nutzen denselben Mechanismus: Schlüssel ist
  der Feldname (bzw. der Name im Code), unter dem der Executor den Wert
  ablegt. Der Name in `outputs` startet gleich dem Feldnamen, ist umbenennbar
  und graph-weit eindeutig („Antwort“, „Antwort2“); Feldnamen selbst müssen
  nur innerhalb des Bausteins eindeutig sein. Felder stehen standardmäßig auf
  der Leinwand. Der Gesamtwert (`value`) dieser Bausteine ist nicht
  erreichbar. Ändert man einen Feldnamen, entsteht ein neuer Schlüssel; Name
  und Flag beginnen neu.
- „Für jedes Element“ liefert je Runde ein flaches Objekt aus den benannten
  Werten des Unterplans (`[{Erkenner: …, Gefunden: …}, …]`).
- In Zweigen und „Für jedes Element“ sind die Werte der äußeren Ebene unter
  denselben Namen erreichbar, auch als `{{global.Name}}`.

Ein leerer Text erzeugt keinen `value`-Output. `humanApproval`, `dialogInput`
und `mediaInput` liefern den Status `waitingForApproval`; nicht registrierte
Primitives erhalten den Status `skipped` und keine Outputs.

Executoren mit rein textuellem Ergebnis setzten früher zusätzlich zu `value`
einen identischen `text`-Output — ungenutzte Redundanz, inzwischen entfernt.
`value` ist der einzige primäre Ausgabeschlüssel.

## Registrierte Executor

| Primitive | Status | Outputs |
| --- | --- | --- |
| `stringInput` | ausgefuehrt | `value` (`string`) |
| `script` | ausgefuehrt | Ein Output je `workflow_output("name", "typ", wert)`-Aufruf (nur Script-Container; Name und Typ als String-Literale; `string`, `number`, `boolean`, `datetime`, `json`). Ohne solche Aufrufe liefert der Executor die Variable `output` als `value`; der Builder führt dafür keinen Wert, sie ist also nicht erreichbar. Laufzeitvariablen stehen nachfolgenden Templates zur Verfuegung |
| `prompt` mit Text oder Entscheidung | ausgefuehrt | `value` (`string`) |
| `prompt` strukturiert | ausgefuehrt | ein flacher `string`-Output je konfiguriertem Feld, ohne umschliessenden Knotennamen (kein `value`-Gesamtwert mehr adressierbar) |
| `prompt` mit Bild | ausgefuehrt | `value` (`media`); das generierte Bild wird als Team-Datei referenziert |
| `conditionalFlow` | ausgefuehrt | `value` (`string`, Ergebnis des gewaehlten Zweigs oder Begruendung); Resultat-Metadaten: `selectedNodeId`, `selectedBranchId`, `selectedBranchLabel` |
| `iterativeRefinement` | ausgefuehrt | `value` (`string`) |
| `readFile` | ausgefuehrt | `value` (`string`, UTF-8-Dateiinhalt) |
| `readEmail` | ausgefuehrt | `value`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit E-Mail | ausgefuehrt | `value` (`string`, Nachrichtentext), `sender`, `subject` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit WhatsApp/SMS | ausgefuehrt | `value` (`string`, Nachrichtentext), `sender` (`string`), `receivedAt` (`datetime`) |
| `sendChannelMessage` | ausgefuehrt | `value`, `recipient`, `channelId`, `providerMessageId` (je `string`) |
| `notificationSend` | ausgefuehrt | keine — reiner Seiteneffekt ohne fachlichen Rückgabewert |
| `humanApproval` | wartet auf Freigabe | `value` (`string`) |
| `dialogInput` | wartet auf Formulareingabe | nach dem Absenden: ein flacher, typisierter Output pro Feld, ohne umschliessenden Knotennamen (kein `value`-Gesamtwert mehr adressierbar) |
| `mediaInput` | wartet auf ein Bild; Nutzer wählt Kamera (optional als Dokumentenscan) oder Galerie | nach dem Absenden: `value` (`media`) |
| `modelInference` | ausgefuehrt | `value` (`json`: Modell-ID und Tensoren mit Semantik, Form, Typ und Base64-Daten), `modelId` (`string`) |
| `writeFile` | ausgefuehrt | siehe nächster Abschnitt |
| `documentLookup` | ausgefuehrt | `value` (`string`: verständliches Suchergebnis), `found` (`boolean`), `record` (`json` mit Fachfeldern oder `null`), `message` (`string`) |
| `saveDocument` | ausgefuehrt | `value` (`string`: „Datensätze gespeichert“), `created` (`boolean`), `count` (`number`), `records` (`json`: gespeicherte Fachfelder) |
| `tableFromCollection` | ausgefuehrt | siehe „Sammlung als Tabelle" |
| `readWebhook` | ausgefuehrt; Lauf ohne Webhook-Ereignis bricht mit einer Meldung ab | `value` (`json`: Inhalt; bei Text `string`), `method` (`string`), `query` (`json`), `headers` (`json`, ohne Zugangsdaten), `receivedAt` (`datetime`); siehe [`features/webhooks.md`](./features/webhooks.md) |
| `shopware` | ausgefuehrt (lokale Runtime); je nach `config.action` | Listen-Aktionen (`searchOrders`, `searchProducts`, `searchCustomers`, `query`): `value` (`json`: Liste), `count`, `total` (`number`), `found` (`boolean`); `getOrder`: `value` (`json`), `orderNumber`, `status`, `paymentStatus`, `deliveryStatus`, `customerEmail` (`string`), `total` (`number`); `changeOrderStatus`: `value` (`json`), `previousStatus`, `newStatus` (`string`), `changed` (`boolean`); `updateProduct`: `value` (`json`), `changed` (`boolean`); siehe [`features/shopware.md`](./features/shopware.md) |
| `httpRequest` | ausgefuehrt (lokale Runtime); ohne Dienst (Cloud) bricht er mit einer Meldung ab | `value` (`json`: geparster JSON-Body, sonst Text, leer `null`), `status` (`number`), `ok` (`boolean`), `headers` (`json`, ohne `set-cookie`); siehe [`features/verbindungen.md`](./features/verbindungen.md) |

## Sammlung als Tabelle

`tableFromCollection` liest eine komplette Datensammlung (kein Filter) und
gibt sie als `table`-Wert (`{columns: string[], rows: unknown[][]}`) weiter —
Spalten sind die Vereinigung aller Feldnamen über alle Datensätze, fehlende
Felder werden pro Zeile zu `null`. Existiert die Sammlung nicht, liefert der
Baustein eine leere Tabelle statt eines Fehlers.

| Output | Typ | Bedeutung |
| --- | --- | --- |
| `value` | `table` | Spalten und Zeilen der Sammlung |
| `rowCount` | `number` | Anzahl gelesener Datensätze |

## Datei schreiben

`writeFile` akzeptiert genau einen primaeren Vorgaengerwert. Textwerte werden
als UTF-8 geschrieben; `file`- und `media`-Referenzen werden über den
`TeamFileContentReader` als Bytes geladen; `table`-Werte (z. B. von
`tableFromCollection`) werden als `.xlsx`-Datei geschrieben. Bei Bildern
übernimmt der Executor MIME-Type und Endung der gespeicherten Version, bei
Tabellen MIME-Type und Endung von XLSX. Sein primaerer Output ist ein
`file`- bzw. `media`-Wert; zusaetzlich liefert der Executor:

| Output | Typ | Bedeutung |
| --- | --- | --- |
| `fileId` | `string` | Stabile ID der Datei |
| `versionId` | `string` | ID der gerade geschriebenen Version |
| `displayName` | `string` | Dateiname |
| `contentType` | `string` | MIME-Type |
| `sizeBytes` | `number` | UTF-8-Groesse des Inhalts |
| `folderId` | `json` | Ordner-ID oder `null` |
| `isNewFile` | `boolean` | `true` bei einer neu angelegten Datei |

Heißt der Hauptwert `Bericht`, verwenden Templates `{{Bericht}}`
(primaerer Datei-/Bildwert) und die weiteren Werte unter ihren Namen, etwa
`{{DateiId}}` oder `{{Dateiname}}`.

## Nicht implementierte Primitives

`toolCall` und `validation` sind im Frontend und im Workflow-Enum vorhanden,
aber nicht im Executor-Registry registriert. Sie werden deshalb derzeit
uebersprungen und liefern keine Outputs.

Der Flutter-Client kennt dieselben Schlüssel aus einer einzigen Quelle:
`outputFieldsOf` in
`lib/features/task_builder/domain/entities/workflow_node_outputs.dart`
(Plugins: `PluginNodeConfig.outputFields`). Panel (`NodeOutputChips`),
`#`-Suche und die Namensvergabe im Cubit fragen dort ab. Ändert sich diese
Tabelle, müssen diese Datei und die Standardnamen in
`assets/translations/*.json` (`task_builder.output_field_names.<schlüssel>`)
mitgezogen werden (siehe [`features/aufgabe.md`](./features/aufgabe.md)
§ UI-Prinzipien).

## Verwandt

- [`backend-struktur.md`](./backend-struktur.md)
- [`features/aufgabe.md`](./features/aufgabe.md)

`textToSpeech` liefert `value` (`audio`): die gesprochene Aufnahme als Team-Datei, sowohl mit einem Sprachmodell als auch mit einem ONNX-Modell. Die Oberfläche zeigt ihn mit Lautsprecher-Symbol und eigener Farbe. `speechToText` liefert `value` (`string`) mit dem Transkript.
