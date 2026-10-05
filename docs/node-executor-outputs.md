# Node-Executor-Outputs

> Referenz fuer die Resultate der Backend-Executoren unter
> `functions/src/features/task_execution/infrastructure/genkit/executors/`.

## Ergebnisvertrag

Jeder Executor liefert ein `NodeExecutionResult` mit einem `outputs`-Objekt.
Ein Output hat einen der Typen `string`, `datetime`, `number`, `boolean`,
`json`, `file`, `media`, `audio` oder `table`. Ein ausgefuehrter Baustein mit einem
fachlichen Rückgabewert stellt ihn unter `value` bereit. Reine
Seiteneffekt-Bausteine ohne fachlichen Rückgabewert (aktuell:
`notificationSend`) liefern ein leeres `outputs`-Objekt — der Baustein
bekommt dafür clientseitig auch keinen Ausgabenamen (siehe
`WorkflowPrimitive.hasNoOutput` in `workflow_node.dart`, angewendet sowohl
beim Anlegen in `task_builder_cubit.dart` als auch selbstheilend beim Laden
in `task_document_mapper.dart`). Kanten bestimmen weiterhin nur Reihenfolge
und Verzweigung; ein Executor erhaelt die `value`-Outputs seiner direkten
Vorgaenger, nicht mehr den letzten Textwert eines Runs.

`media`, `audio` und `file` enthalten eine fachliche Referenz mit `fileId`, `versionId`,
`displayName`, `contentType` und `sizeBytes`. Der konkrete Speicherort bleibt
innerhalb der Dateiinfrastruktur; erst der konsumierende Executor liest die
referenzierte Version. Der primäre Wert eines benannten Bausteins ist
ausschließlich per `{{ausgabename}}` erreichbar — die ältere, zweistufige
Form `{{ausgabename.value}}` aus der Zeit vor eindeutigen Einzelnamen löst
seit `template-expression-resolver.ts` (`nodeOutputContextFor`/
`secondaryOutputsOf`) nicht mehr auf. Benannte Nebenoutputs bleiben per
Dot-Pfad erreichbar, etwa `{{eingang.sender}}` oder `{{bericht.fileId}}`.
Bausteine mit mehreren fachlichen Ausgabewerten (strukturierte
Prompt-Ausgabe, Dialogeingabe) haben keinen eigenen Ausgabenamen — hier ist
jedes Feld direkt und flach unter seinem eigenen, graph-weit eindeutigen
Namen erreichbar, z.B. `{{Name}}`.

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
| `script` | ausgefuehrt | `value` (`string`); interne Laufzeitvariablen stehen nachfolgenden Templates zur Verfuegung |
| `prompt` mit Text oder Entscheidung | ausgefuehrt | `value` (`string`) |
| `prompt` strukturiert | ausgefuehrt | ein flacher `string`-Output je konfiguriertem Feld, ohne umschliessenden Knotennamen (kein `value`-Gesamtwert mehr adressierbar) |
| `prompt` mit Bild | ausgefuehrt | `value` (`media`); das generierte Bild wird als Team-Datei referenziert |
| `conditionalFlow` | ausgefuehrt | `value` (`string`, Ergebnis des gewaehlten Zweigs oder Begruendung); Resultat-Metadaten: `selectedNodeId`, `selectedBranchId`, `selectedBranchLabel` |
| `iterativeRefinement` | ausgefuehrt | `value` (`string`) |
| `readFile` | ausgefuehrt | `value` (`string`, UTF-8-Dateiinhalt) |
| `readEmail` | ausgefuehrt | `value`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit E-Mail | ausgefuehrt | `value`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit WhatsApp/SMS | ausgefuehrt | `value`, `sender`, `message` (je `string`), `receivedAt` (`datetime`) |
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

Hat der Knoten den Ausgabenamen `bericht`, koennen Templates beispielsweise
`{{bericht}}` (primaerer Datei-/Bildwert), `{{bericht.fileId}}`,
`{{bericht.versionId}}` oder `{{bericht.displayName}}` verwenden.

## Nicht implementierte Primitives

`toolCall` und `validation` sind im Frontend und im Workflow-Enum vorhanden,
aber nicht im Executor-Registry registriert. Sie werden deshalb derzeit
uebersprungen und liefern keine Outputs.

Der Flutter-Client kennt dieselben Nebenoutput-Namen clientseitig noch einmal
— nicht dupliziert, sondern aus einer einzigen Quelle:
`lib/features/task_builder/domain/entities/workflow_node_outputs.dart`.
Sowohl die Anzeige im Konfigurations-Overlay (`NodeOutputChips`) als auch die
`#`-Suche (`templateExpressionSuggestions`) fragen dort ab, welche Felder ein
Baustein-Typ hat — ändert sich diese Tabelle hier, muss diese Datei
mitgezogen werden (siehe [`features/aufgabe.md`](./features/aufgabe.md)
§ UI-Prinzipien).

## Verwandt

- [`backend-struktur.md`](./backend-struktur.md)
- [`features/aufgabe.md`](./features/aufgabe.md)

`textToSpeech` liefert `value` (`audio`): die gesprochene Aufnahme als Team-Datei, sowohl mit einem Sprachmodell als auch mit einem ONNX-Modell. Die Oberfläche zeigt ihn mit Lautsprecher-Symbol und eigener Farbe. `speechToText` liefert `value` (`string`) mit dem Transkript.
