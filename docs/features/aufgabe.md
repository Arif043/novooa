# Feature: Aufgabe

> Der Task Builder ist das Herzstueck von novooa. Nutzer:innen bauen
> Automatisierungen aus Bausteinen zusammen.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`arbeitsplaene.md`](./arbeitsplaene.md) ·
[`zeitplan.md`](./zeitplan.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Visualisierung und Bearbeitung von `TaskDefinition`-Aggregaten. Bausteine
werden auf einer Leinwand konfiguriert, verbunden, sofort gespeichert und als
Aufgabe ausgefuehrt.

## Verantwortlichkeiten

- Bausteine per Drag-and-Drop auf die Leinwand ziehen.
- Knoten selektieren, loeschen, verschieben und verbinden.
- Typsichere Felder je Primitive im NodeInspector anbieten.
- Titel und Ziel bearbeiten sowie Aufgaben ausfuehren.
- Jede Mutation sofort ueber `TaskRepository.saveTask()` persistieren.
- Sichtbare Strings auf Deutsch halten.

## Domain und UI

```
features/task_builder/
├── domain/          # TaskDefinition, WorkflowNode, WorkflowEdge, Repository
├── infrastructure/  # Firestore-Mapping und Firebase-Repository
└── presentation/    # Builder-Cubit, Seite, Palette, Canvas, Inspector
```

`TaskDefinition` ist ein immutable Aggregate Root. Alle Mutationen erzeugen
ueber `copyWith` eine neue Instanz. Node-IDs bleiben stabil, eine Aufgabe hat
hoechstens einen selektierten Knoten und Kanten duerfen nur vorhandene Knoten
referenzieren.

## Primitives

| Enum-Wert | UI-Label | Beschreibung | Status |
| --- | --- | --- | --- |
| `stringInput` | Texteingabe | Gibt festen Text weiter | Implementiert |
| `script` | Script | Fuehrt Python mit einer explizit konfigurierten Eingabe aus; in der lokalen Runtime im abgeschotteten Container `novooa-script` mit vollem Python (siehe [`../local-runtime.md`](../local-runtime.md) § Script-Dienst) | Implementiert |
| `prompt` | Prompt | LLM-Aufruf mit Vorlage und Variablen; optional ein [Mitarbeiter](./mitarbeiter.md) (System-Prompt + Fähigkeiten) **oder** eigene [Fähigkeiten](./skills.md), nie beides | Implementiert |
| `conditionalFlow` | Bedingter Ablauf | Verzweigt anhand eines Labels (Entscheidungs-Prompt-Vorgänger) oder anhand eigener boolescher Branch-Bedingungen (geführte Wertauswahl, Vergleiche, alle/mindestens eine/genau eine Bedingung, verschachtelt). Bei eigenen Bedingungen lässt sich der Sonst-Pfad im rechten Panel per Checkbox hinzufügen/entfernen; gefüllte Pfade werden nur nach Bestätigung entfernt. Weitere Bedingungen aktivieren einen ausgeschalteten Sonst-Pfad nicht erneut. | Implementiert |
| `iterativeRefinement` | Iterative Verfeinerung | Bewertet und verbessert einen Entwurf; Mitarbeiter oder Fähigkeiten wie beim Prompt | Implementiert |
| `writeFile` | Datei schreiben | Schreibt einen explizit konfigurierten Wert als Datei | Implementiert |
| `readFile` | Datei lesen | Liest eine konkrete Datei-Version | Implementiert |
| `readEmail` | E-Mail lesen | Liest Absender, Betreff und Inhalt eines Events | Microsoft Graph implementiert |
| `readChannelEvent` | Nachricht lesen | Liest E-Mail-, WhatsApp- oder SMS-Events | Implementiert |
| `sendChannelMessage` | Nachricht senden | Sendet E-Mail, WhatsApp oder SMS | Microsoft-Graph-Antworten implementiert |
| `notificationSend` | Push-Benachrichtigung senden | Sendet einen aufgelösten Text als Push-Benachrichtigung an alle Team-Mitglieder | Implementiert |
| `humanApproval` | Freigabe | Haltet den Run bis zur menschlichen Entscheidung an | Implementiert |
| `dialogInput` | Formulareingabe | Pausiert den Run und fragt typisierte Eingaben per Formular ab | Implementiert |
| `mediaInput` | Bild anfordern | Pausiert den Run und fordert ein Bild an; Quelle wird während der Ausführung gewählt; optional Dokumentenscanner (Android, iOS, Web) | Implementiert |
| `modelInference` | Modell ausführen | Prüft explizite Workflow-Zuordnungen gegen das Manifest und führt ein ONNX-Modell aus | Backend-Pipeline implementiert; Runtime-Composition ausstehend |
| `textToSpeech` | Text vorlesen | Text-zu-Sprache über ein verbundenes Sprachmodell (Google AI, ElevenLabs, OpenAI-kompatibel, siehe [`sprachausgabe.md`](./sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Ausgabe | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `speechToText` | Audio transkribieren | Sprache-zu-Text über ein verbundenes Sprachmodell (Google AI, ElevenLabs Scribe, OpenAI-kompatibel, siehe [`sprachausgabe.md`](./sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Eingang | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `forEach` | Für jedes Element | Führt einen eingebetteten Arbeitsplan seriell für jedes Element eines JSON-Arrays aus | Implementiert |
| `documentLookup` | Datensatz suchen | Findet genau einen Datensatz über sichtbare Feldbedingungen | Lokale Runtime implementiert |
| `saveDocument` | Datensatz speichern | Legt ohne Bedingungen einen neuen Datensatz an; mit Feldbedingungen aktualisiert er alle Treffer oder legt bei keinem Treffer einen neuen an | Lokale Runtime implementiert |
| `tableFromCollection` | Sammlung als Tabelle | Liest eine Datensammlung vollständig und gibt sie als fachlichen Tabellen-Wert weiter; „Datei schreiben" speichert einen solchen Wert als `.xlsx` | Lokale Runtime implementiert |
| `readWebhook` | Webhook-Ereignis | Liest den Aufruf, der die Aufgabe über einen [Webhook](./webhooks.md) gestartet hat; liefert `value` (Inhalt), `method`, `query`, `headers`, `receivedAt` | Lokale Runtime implementiert |
| `httpRequest` | HTTP-Anfrage | Ruft die HTTP-API eines externen Systems auf, optional über eine gespeicherte [Verbindung](./verbindungen.md); liefert `value`, `status`, `ok`, `headers` | Lokale Runtime implementiert |
| `toolCall` | Werkzeug-Aufruf | Strukturierter Aufruf eines Werkzeugs | Geplant |
| `validation` | Validierung | Prueft Output gegen Schema oder Regeln | Geplant |

Die vollstaendigen Output-Slots dokumentiert
[`../node-executor-outputs.md`](../node-executor-outputs.md).

## UI-Prinzipien

- Das Aufgabenstudio übernimmt die Inter-Typografie und die abgestuften
  Oberflächen aus [`../DESIGN.md`](../DESIGN.md). `TaskBuilderTheme` bündelt
  diese Gestaltung für Hell- und Dunkelmodus innerhalb des Builders.
  Die gemeinsame Kopfzeile richtet Navigation über der Palette, den
  editierbaren Aufgabentitel über der Arbeitsfläche und KI-Agent sowie
  Benachrichtigungen rechts nebeneinander aus.
- Ausgabe-Labels (Ausgabename und feste Felder) zeigen Farbe und Icon ihres
  `NodeOutputType` (`NodeOutputTypeStyle`, Farben in `OutputTypeColors`).
  Welcher Typ zu welchem Baustein bzw. Feld gehört, steht ausschließlich in
  `workflow_output_types.dart` und spiegelt `docs/node-executor-outputs.md`.
- Links steht eine durchsuchbare, nach Kategorien gruppierte Baustein-Palette.
  Ein Klick fügt den Baustein ein; Drag-and-Drop oder die Plus-Aktion einer Karte
  wählt eine konkrete Anschlussstelle, auch in Verzweigungen und Schleifen.
- Die verschiebbare und zoombare Arbeitsfläche zeigt kompakte Karten mit Typ
  und ID. Gespeicherte `WorkflowEdge`-Verbindungen werden mit Richtungspfeilen
  und vorhandenen Bedingungslabels gezeichnet. Unterpläne erhalten zusätzlich
  beschriftete Verbindungen zu ihrem übergeordneten Baustein.
- Jeder offene Pfad endet mit „Baustein hier verbinden“, auch wenn er bereits
  Bausteine enthält. Unter sämtlichen Zweigen einer Bedingung steht der
  getrennte Anschluss „Nach der Bedingung“ für den übergeordneten Pfad;
  Schleifen bieten analog „Nach der Schleife“. Gestrichelte Rückführungen
  und die Trennlinie kennzeichnen diese Fortsetzung. Diese Anschlüsse sind
  reine Darstellungselemente, keine zusätzlichen gespeicherten Bausteine.
- Pfade behalten ihre eigene horizontale Spalte bis zum letzten Anschluss;
  unterschiedlich lange Zweige werden nicht zeilenweise neu zentriert.
  `WorkflowCanvasOptions.showReturnEdges` steuert die Rückführungspfeile
  (standardmäßig `false`). Layout und Ausführung bleiben davon unabhängig.
- Ein Klick auf eine Karte öffnet rechts ein Konfigurations-Overlay im selben
  Provider-Kontext. Alle bisherigen Editoren, Anhänge, Ausgabenamen und
  Workflow-Ausgabewerte bleiben dort verfügbar. Änderungen aktualisieren das
  Overlay unmittelbar. Schließen ist per Schaltfläche oder Escape möglich.
- Der `script`-Baustein zeigt im Konfigurations-Overlay nur eine kompakte
  Vorschau des Codes (wenige Zeilen, Zeilenumbruch an, moderates Wachstum
  bis zum internen Scrollen). Für ernsthaftes Schreiben reicht das
  schmale Panel nicht — ein „Vollbild bearbeiten"-Knopf öffnet denselben
  `CodeController` in einem `Dialog.fullscreen` (`ScriptCodeEditor`,
  `showScriptFullscreenEditor`). Beide Ansichten teilen dieselbe
  Controller-Instanz, es gibt keinen separaten Speicherzustand.
- Auf schmalen Fenstern wird die linke Palette über „Bausteine“ eingeblendet.
- `TaskBuilderCubit.addConnectedNode` verbindet einen neuen Baustein mit
  `afterId` im Hauptgraphen oder mit `ownerId`/`branchId` im Unterplan;
  `channelKind` erhält die Kanalwahl auch innerhalb eines Unterplans.
- Autosave statt Speichern-Dialog.
- Template-fähige Texteingaben aller Bausteine stellen Template-Ausdrücke als
  Labels dar. Mit `#` öffnet sich eine Suche nach Workflow-Ausgabewerten und
  statisch erkennbaren Script-Variablen aus dem erreichbaren Vorgängerpfad.
  Persistiert bleibt der unveränderte Ausdruck `{{name}}`; die Label-
  Darstellung ist reine UI. Feste Nebenoutputs eines Bausteins (z.B.
  `speichern4.created`) sind dort standardmäßig ausgeblendet und erst über
  den Filter „Feste Felder" einblendbar — die Suche bleibt für den
  Normalfall (primäre Ausgabenamen, Variablen) einfach.
- Feste Nebenoutputs sind auch im rechten Konfigurations-Overlay bewusst
  anders gestaltet als der editierbare Ausgabename: outlined statt gefüllt,
  gedämpfte statt Akzentfarbe, kein Stift-Icon — sie beschreiben feste
  Argumente des Baustein-Typs, keine vom Nutzer gewählten Namen. Antippen
  kopiert die fertige Referenz (`{{ausgabename.feld}}`) in die
  Zwischenablage, statt eine Umbenennung anzubieten. Sie erscheinen nie auf
  der Arbeitsfläche selbst, nur im Overlay (`NodeOutputChips`). Einzige
  Quelle dafür, welche Felder ein Baustein-Typ hat:
  `domain/entities/workflow_node_outputs.dart` — genutzt von diesem Overlay
  und von der `#`-Suche gleichermaßen.
- Anlass statt technischer Konfiguration.
- Inline-Vorschau, wo sie den naechsten Schritt verstaendlicher macht.
- Sofortiges Feedback bei Mutationen.
- Aussagekraeftige Leer- und Fehlerzustaende.

## Referenzen

| Bereich | Dokument |
| --- | --- |
| Laufzeit, Graph-Runner, Freigaben, lokale Ausfuehrung | [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md) |
| Modellprovider und Executor-Verhalten | [`aufgabe-executoren.md`](./aufgabe-executoren.md) |
| Alle Executor-Output-Slots | [`../node-executor-outputs.md`](../node-executor-outputs.md) |

## Definition of Done

- [ ] Bausteine lassen sich auf die Leinwand ziehen, verbinden, selektieren,
      verschieben und loeschen.
- [ ] Der NodeInspector persistiert passende Felder sofort.
- [ ] Titel und Ziel sind editierbar; eine Aufgabe kann ausgefuehrt werden.
- [ ] Der Cubit emittiert nach jeder Mutation einen neuen immutable State.
- [ ] Leer- und Fehlerzustaende sind auf Deutsch.

## Offene Fragen

- Welche Primitives benoetigen zuerst einen `toolCall`-Executor?
- Welche Validierungsregeln sollen fuer `validation` im MVP unterstuetzt werden?
- Welche Teile der Ausfuehrung sollen langfristig lokal laufen?

## Verwandt

- [`aufgabe-ausfuehrung.md`](./aufgabe-ausfuehrung.md)
- [`aufgabe-executoren.md`](./aufgabe-executoren.md)
- [`dateien.md`](./dateien.md)
