# Node-Executor-Outputs

> Referenz fuer die Resultate der Backend-Executoren unter
> `functions/src/task-executors/`.

## Ergebnisvertrag

Jeder Executor liefert ein `NodeExecutionResult` mit einem `outputs`-Objekt.
Ein Output hat einen der Typen `string`, `datetime`, `number`, `boolean` oder
`json`. Der regulaere Datenfluss zwischen verbundenen Knoten verwendet nur den
Output `text`. Benannte Outputs sind ueber den Referenznamen eines Knotens in
Templates verfuegbar, etwa `{{eingang.sender}}`.

Ein leerer Text erzeugt keinen `text`-Output. `humanApproval` liefert den
Status `waitingForApproval`; nicht registrierte Primitives erhalten den Status
`skipped` und keine Outputs.

## Registrierte Executor

| Primitive | Status | Outputs |
| --- | --- | --- |
| `stringInput` | ausgefuehrt | `text` (`string`) |
| `script` | ausgefuehrt | `text` (`string`); interne Laufzeitvariablen stehen nachfolgenden Templates zur Verfuegung |
| `prompt` mit Text | ausgefuehrt | `text` (`string`) |
| `prompt` mit Entscheidung | ausgefuehrt | `text` (`string`, gewaehlte Option) |
| `prompt` strukturiert | ausgefuehrt | `text` (`string`, JSON) und ein `string`-Output fuer jedes konfigurierte Feld |
| `conditionalFlow` | ausgefuehrt | `text` (`string`, Ergebnis des gewaehlten Zweigs oder Begruendung); Resultat-Metadaten: `selectedNodeId`, `selectedBranchId`, `selectedBranchLabel` |
| `iterativeRefinement` | ausgefuehrt | `text` (`string`) |
| `readFile` | ausgefuehrt | `text` (`string`, UTF-8-Dateiinhalt) |
| `readEmail` | ausgefuehrt | `text`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit E-Mail | ausgefuehrt | `text`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit WhatsApp/SMS | ausgefuehrt | `text`, `sender`, `message` (je `string`), `receivedAt` (`datetime`) |
| `sendChannelMessage` | ausgefuehrt | `text`, `recipient`, `channelId`, `providerMessageId` (je `string`) |
| `humanApproval` | wartet auf Freigabe | `text` (`string`) |
| `writeFile` | ausgefuehrt | siehe nächster Abschnitt |

## Datei schreiben

`writeFile` erhaelt den Text des Vorgaenger-Knotens und schreibt ihn als neue
Datei oder neue Version. Der JSON-String in `text` bleibt fuer den regulaeren
Datenfluss erhalten. Zusaetzlich liefert der Executor:

| Output | Typ | Bedeutung |
| --- | --- | --- |
| `fileId` | `string` | Stabile ID der Datei |
| `versionId` | `string` | ID der gerade geschriebenen Version |
| `storagePath` | `string` | Team-scoped Firebase-Storage-Pfad |
| `displayName` | `string` | Dateiname |
| `contentType` | `string` | MIME-Type |
| `sizeBytes` | `number` | UTF-8-Groesse des Inhalts |
| `folderId` | `json` | Ordner-ID oder `null` |
| `isNewFile` | `boolean` | `true` bei einer neu angelegten Datei |

Hat der Knoten den Referenznamen `bericht`, koennen Templates beispielsweise
`{{bericht.fileId}}`, `{{bericht.versionId}}` oder
`{{bericht.storagePath}}` verwenden.

## Nicht implementierte Primitives

`toolCall` und `validation` sind im Frontend und im Workflow-Enum vorhanden,
aber nicht im Executor-Registry registriert. Sie werden deshalb derzeit
uebersprungen und liefern keine Outputs.

## Verwandt

- [`backend-struktur.md`](./backend-struktur.md)
- [`features/aufgabe.md`](./features/aufgabe.md)
