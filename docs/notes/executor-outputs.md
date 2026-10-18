# Registrierte Executor-Outputs

> Welche benannten Outputs (Schlüssel und Typ) jeder registrierte Executor liefert; die Schlüssel sind technischer Vertrag zwischen Executor und Builder.

Gehört zu: [Aufgabe](../index/aufgabe.md)

Executoren: `functions/src/features/task_execution/infrastructure/genkit/executors/`.

| Primitive | Status | Outputs |
| --- | --- | --- |
| `stringInput` | ausgefuehrt | `value` (`string`) |
| `script` | ausgefuehrt | Ein Output je `workflow_output("name", "typ", wert)`-Aufruf (nur Script-Container; Name und Typ als String-Literale; `string`, `number`, `boolean`, `datetime`, `json`). Ohne solche Aufrufe liefert der Executor die Variable `output` als `value`; der Builder führt dafür keinen Wert, sie ist also nicht erreichbar. Laufzeitvariablen stehen nachfolgenden Templates zur Verfuegung |
| `prompt` mit Text oder Entscheidung | ausgefuehrt | `value` (`string`) |
| `prompt` strukturiert | ausgefuehrt | ein flacher, typisierter Output je konfiguriertem Feld (`string`, `number`, `boolean`), ohne umschliessenden Knotennamen und ohne `value`; zusätzliche Felder des Modells fallen weg |
| `prompt` mit Bild | ausgefuehrt | `value` (`media`); das generierte Bild wird als Team-Datei referenziert |
| `conditionalFlow` | ausgefuehrt | `value` (`string`, Ergebnis des gewählten Zweigs, sonst dessen Name; ohne gewählten Zweig kein `value`); Resultat-Metadaten: `selectedNodeId`, `selectedBranchId`, `selectedBranchLabel` |
| `iterativeRefinement` | ausgefuehrt | `value` (`string`) |
| `readFile` | ausgefuehrt | `value` (`string`, UTF-8-Dateiinhalt) |
| `readEmail` | ausgefuehrt | `value`, `sender`, `subject`, `message` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit E-Mail | ausgefuehrt | `value` (`string`, Nachrichtentext), `sender`, `subject` (je `string`), `receivedAt` (`datetime`) |
| `readChannelEvent` mit WhatsApp/SMS | ausgefuehrt | `value` (`string`, Nachrichtentext), `sender` (`string`), `receivedAt` (`datetime`) |
| `sendChannelMessage` | ausgefuehrt | `value`, `recipient`, `channelId`, `providerMessageId` (je `string`) |
| `notificationSend` | ausgefuehrt | keine — reiner Seiteneffekt ohne fachlichen Rückgabewert |
| `humanApproval` | wartet auf Freigabe | `value` (`string`) |
| `dialogInput` | wartet auf Formulareingabe | nach dem Absenden: ein flacher, typisierter Output pro Feld, ohne umschliessenden Knotennamen und ohne `value` |
| `mediaInput` | wartet auf ein Bild; Nutzer wählt Kamera (optional als Dokumentenscan) oder Galerie | nach dem Absenden: `value` (`media`) |
| `modelInference` | ausgefuehrt | `value` (`json`: Modell-ID und Tensoren mit Semantik, Form, Typ und Base64-Daten), `modelId` (`string`) |
| `writeFile` | ausgefuehrt | siehe nächster Abschnitt |
| `documentLookup` | ausgefuehrt | `value` (`string`: verständliches Suchergebnis), `found` (`boolean`), `record` (`json` mit Fachfeldern oder `null`), `message` (`string`) |
| `saveDocument` | ausgefuehrt | `value` (`string`: „Datensätze gespeichert“), `created` (`boolean`), `count` (`number`), `records` (`json`: gespeicherte Fachfelder) |
| `tableFromCollection` | ausgefuehrt | siehe „Sammlung als Tabelle" |
| `readWebhook` | ausgefuehrt; Lauf ohne Webhook-Ereignis bricht mit einer Meldung ab | `value` (`json`: Inhalt; bei Text `string`), `method` (`string`), `query` (`json`), `headers` (`json`, ohne Zugangsdaten), `receivedAt` (`datetime`); siehe [Webhooks](../index/webhooks.md) |
| `shopware` | ausgefuehrt (lokale Runtime); je nach `config.action` | Listen-Aktionen (`searchOrders`, `searchProducts`, `searchCustomers`, `query`): `value` (`json`: Liste), `count`, `total` (`number`), `found` (`boolean`); `getOrder`: `value` (`json`), `orderNumber`, `status`, `paymentStatus`, `deliveryStatus`, `customerEmail` (`string`), `total` (`number`); `changeOrderStatus`: `value` (`json`), `previousStatus`, `newStatus` (`string`), `changed` (`boolean`); `updateProduct`: `value` (`json`), `changed` (`boolean`); siehe [Shopware](./shopware-plugin.md) |
| `httpRequest` | ausgefuehrt (lokale Runtime); ohne Dienst (Cloud) bricht er mit einer Meldung ab | `value` (`json`: geparster JSON-Body, sonst Text, leer `null`), `status` (`number`), `ok` (`boolean`), `headers` (`json`, ohne `set-cookie`); siehe [Verbindungen](../index/verbindungen.md) |

Zusätzlich: `textToSpeech` liefert `value` (`audio`, die Aufnahme als
Team-Datei, mit Sprachmodell wie mit ONNX-Modell; Lautsprecher-Symbol und
eigene Farbe), `speechToText` liefert `value` (`string`, Transkript).

**Mitziehen bei Änderungen:** Der Client kennt dieselben Schlüssel aus einer
Quelle, `outputFieldsOf` in
`lib/features/task_builder/domain/entities/workflow_node_outputs.dart`
(Plugins: `PluginNodeConfig.outputFields`); Typen in
`workflow_output_types.dart`. Panel, `#`-Suche und Namensvergabe fragen dort
ab. Ändert sich die Tabelle, auch diese Dateien und die Standardnamen in
`assets/translations/*.json` (`task_builder.output_field_names.<schlüssel>`)
anpassen.

## Siehe auch

- [Ergebnisvertrag eines Bausteins](./node-ergebnisvertrag.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
- [Datei-Bausteine](./datei-bausteine.md) — Outputs von „Datei schreiben“
- [Sammlung als Tabelle](./sammlung-als-tabelle.md)
