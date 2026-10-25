# Bausteinkatalog

> Alle `WorkflowPrimitive`-Werte mit UI-Label, Beschreibung und Umsetzungsstand; neue Bausteine bekommen hier eine Zeile.

Gehört zu: [Aufgabe](../index/aufgabe.md)

Neuer oder geänderter Baustein: Auch das Produktwissen des KI-Agenten in
`functions/src/features/task_execution/infrastructure/genkit/assistant/subagents/novooa-product-knowledge.ts`
pflegen. Darf der Agent ihn per `addNode` anlegen, gehört er zusätzlich in
`taskBuilderAssistantPrimitives` und in die Client-Factory.
`workflow_node.dart` hält das Enum synchron zu dieser Tabelle.

| Enum-Wert | UI-Label | Beschreibung | Status |
| --- | --- | --- | --- |
| `stringInput` | Texteingabe | Gibt festen Text weiter | Implementiert |
| `script` | Script | Fuehrt Python aus; in der lokalen Runtime im abgeschotteten Container `novooa-script` mit vollem Python (siehe [Script-Dienst: Schnittstelle](../notes/script-dienst-schnittstelle.md)). Liest Werte nur per `workflow_input("pfad")` (siehe [Script: Workflow-Eingabewerte](./script-workflow-input.md)) und liefert sie nur per `workflow_output(name, type, value)` (siehe [Script: Workflow-Ausgabewerte](./script-workflow-output.md)); PyPI-Pakete pro Baustein, installiert per Klick (siehe [Script: Python-Pakete](./script-pakete.md)) | Implementiert |
| `prompt` | Prompt | LLM-Aufruf mit Vorlage und Workflow-Werten; optional ein [Mitarbeiter](../index/mitarbeiter.md) (System-Prompt + Fähigkeiten) **oder** eigene [Fähigkeiten](../index/faehigkeiten.md), nie beides | Implementiert |
| `conditionalFlow` | Bedingter Ablauf | Verzweigt anhand sichtbarer boolescher Branch-Bedingungen (geführte Wertauswahl, Vergleiche passend zum Datentyp des Werts, alle/mindestens eine/genau eine Bedingung, verschachtelt), immer bearbeitbar. Hinter einem Entscheidungs-Prompt entstehen Zweige `{{Antwort}}` *ist gleich* `<Antwort>`; ein Hinweis nennt Antworten ohne Zweig und ergänzt sie per „Fehlende Zweige ergänzen“. Die Leinwand beschriftet jeden Zweig mit seiner Bedingung (z. B. „Antwort ist Ja“, `branchConditionSummary`), ohne Bedingung „Sonst“; die Panel-Karten heißen fest „Bedingung 1, 2 …“. Zweige werden nicht umbenannt. Bei eigenen Bedingungen lässt sich der Sonst-Pfad im rechten Panel per Checkbox hinzufügen/entfernen; gefüllte Pfade werden nur nach Bestätigung entfernt. Weitere Bedingungen aktivieren einen ausgeschalteten Sonst-Pfad nicht erneut. | Implementiert |
| `iterativeRefinement` | Iterative Verfeinerung | Bewertet und verbessert einen Entwurf; Mitarbeiter oder Fähigkeiten wie beim Prompt | Implementiert |
| `teamwork` | Teamarbeit | Ein Orchestrator verteilt Aufträge an 1–5 [Mitarbeiter](../index/mitarbeiter.md) (Zuständigkeit und Modell je Baustein) und liefert ein Ergebnis mit typisierten Feldern, auch Textdateien (siehe [Baustein „Teamarbeit“](./teamwork-baustein.md)) | Implementiert |
| `writeFile` | Datei schreiben | Schreibt einen explizit konfigurierten Wert als Datei | Implementiert |
| `readFile` | Datei lesen | Liest eine konkrete Datei-Version | Implementiert |
| `readEmail` | E-Mail lesen | Liest Absender, Betreff und Inhalt eines Events | Microsoft Graph implementiert |
| `readChannelEvent` | Nachricht lesen | Liest E-Mail-, WhatsApp-, SMS-, Telegram- oder Instagram-Events (außer E-Mail in der Palette deaktiviert, „Bald verfügbar“); der Nachrichtentext ist der Hauptwert, Absender, Betreff (nur E-Mail) und Ankunftszeit sind weitere Werte | Implementiert |
| `sendChannelMessage` | Nachricht senden | Sendet E-Mail, WhatsApp, SMS, Telegram oder Instagram (außer E-Mail nur Platzhalter in der Palette, deaktiviert) | Microsoft-Graph-Antworten implementiert |
| `notificationSend` | Push-Benachrichtigung senden | Sendet einen aufgelösten Text als Push-Benachrichtigung an alle Team-Mitglieder | Implementiert |
| `humanApproval` | Freigabe | Haltet den Run bis zur menschlichen Entscheidung an | Implementiert |
| `dialogInput` | Formulareingabe | Pausiert den Run und fragt typisierte Eingaben per Formular ab | Implementiert |
| `mediaInput` | Bild anfordern | Pausiert den Run und fordert ein Bild an; Quelle wird während der Ausführung gewählt; optional Dokumentenscanner (Android, iOS, Web) | Implementiert |
| `modelInference` | Modell ausführen | Modell per Suche im globalen Modellkatalog (plus eigene Modelle) wählen, eingrenzbar über Chips für Bereich, Aufgabe und Sprache; die Runtime cacht es sofort im Hintergrund. Prüft explizite Workflow-Zuordnungen gegen das Manifest und führt ein ONNX-Modell aus | Backend-Pipeline implementiert; Runtime-Composition ausstehend |
| `textToSpeech` | Text vorlesen | Text-zu-Sprache über ein verbundenes Sprachmodell (Google AI, ElevenLabs, OpenAI-kompatibel, siehe [`../index/sprachausgabe.md`](../index/sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Ausgabe | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `speechToText` | Audio transkribieren | Sprache-zu-Text über ein verbundenes Sprachmodell (Google AI, ElevenLabs Scribe, OpenAI-kompatibel, siehe [`../index/sprachausgabe.md`](../index/sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Eingang | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `forEach` | Für jedes Element | Führt einen eingebetteten Arbeitsplan seriell für jedes Element eines JSON-Arrays aus | Implementiert |
| `documentLookup` | Datensatz suchen | Findet genau einen Datensatz über sichtbare Feldbedingungen | Lokale Runtime implementiert |
| `saveDocument` | Datensatz speichern | Legt ohne Bedingungen einen neuen Datensatz an; mit Feldbedingungen aktualisiert er alle Treffer oder legt bei keinem Treffer einen neuen an | Lokale Runtime implementiert |
| `tableFromCollection` | Sammlung als Tabelle | Liest eine Datensammlung vollständig und gibt sie als fachlichen Tabellen-Wert weiter; „Datei schreiben" speichert einen solchen Wert als `.xlsx` | Lokale Runtime implementiert |
| `readWebhook` | Webhook-Ereignis | Liest den Aufruf, der die Aufgabe über einen [Webhook](../index/webhooks.md) gestartet hat; liefert `value` (Inhalt), `method`, `query`, `headers`, `receivedAt` | Lokale Runtime implementiert |
| `shopware` | Shopware-Aktion | Eine Aktion eines Shopware-Shops (`config.action`, `connectionId`, `params`); jede Aktion erscheint als eigener Baustein, siehe [Integrationen](../index/integrationen.md) | Lokale Runtime; Aktionen: Bestellungen suchen/lesen, Bestellstatus ändern, Produkte suchen/ändern, Kunden suchen, Abfrage; siehe [Shopware](./shopware-plugin.md) |
| `httpRequest` | HTTP-Anfrage | Ruft die HTTP-API eines externen Systems auf, optional über eine gespeicherte [Verbindung](../index/verbindungen.md); liefert `value`, `status`, `ok`, `headers` | Lokale Runtime implementiert |
| `toolCall` | Werkzeug-Aufruf | Strukturierter Aufruf eines Werkzeugs | Geplant |
| `validation` | Validierung | Prueft Output gegen Schema oder Regeln | Geplant |

`toolCall` und `validation` sind im Frontend und im Enum vorhanden, aber nicht
in der Executor-Registry; sie werden übersprungen und liefern keine Outputs.

## Siehe auch

- [Registrierte Executor-Outputs](./executor-outputs.md)
- [Bausteine von Plugins](./plugin-bausteine.md)
