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

> Neuer oder geänderter Baustein: Auch das Produktwissen des KI-Agenten in
> `functions/src/features/task_execution/infrastructure/genkit/assistant/subagents/novooa-product-knowledge.ts`
> pflegen. Darf der Agent ihn per `addNode` anlegen, gehört er zusätzlich in
> `taskBuilderAssistantPrimitives` und in die Client-Factory.

| Enum-Wert | UI-Label | Beschreibung | Status |
| --- | --- | --- | --- |
| `stringInput` | Texteingabe | Gibt festen Text weiter | Implementiert |
| `script` | Script | Fuehrt Python mit einer explizit konfigurierten Eingabe aus; in der lokalen Runtime im abgeschotteten Container `novooa-script` mit vollem Python (siehe [`../local-runtime.md`](../local-runtime.md) § Script-Dienst). Dort definiert `workflow_output(name, type, value)` flache, typisierte Workflow-Ausgabewerte (siehe [`aufgabe-executoren.md`](./aufgabe-executoren.md) § Script) | Implementiert |
| `prompt` | Prompt | LLM-Aufruf mit Vorlage und Variablen; optional ein [Mitarbeiter](./mitarbeiter.md) (System-Prompt + Fähigkeiten) **oder** eigene [Fähigkeiten](./skills.md), nie beides | Implementiert |
| `conditionalFlow` | Bedingter Ablauf | Verzweigt anhand sichtbarer boolescher Branch-Bedingungen (geführte Wertauswahl, Vergleiche, alle/mindestens eine/genau eine Bedingung, verschachtelt), immer bearbeitbar. Hinter einem Entscheidungs-Prompt entstehen Zweige `{{Antwort}}` *ist gleich* `<Antwort>`; ein Hinweis nennt Antworten ohne Zweig und ergänzt sie per „Fehlende Zweige ergänzen“. Die Leinwand beschriftet jeden Zweig mit seiner Bedingung (z. B. „Antwort ist Ja“, `branchConditionSummary`), ohne Bedingung „Sonst“; die Panel-Karten heißen fest „Bedingung 1, 2 …“. Zweige werden nicht umbenannt. Bei eigenen Bedingungen lässt sich der Sonst-Pfad im rechten Panel per Checkbox hinzufügen/entfernen; gefüllte Pfade werden nur nach Bestätigung entfernt. Weitere Bedingungen aktivieren einen ausgeschalteten Sonst-Pfad nicht erneut. | Implementiert |
| `iterativeRefinement` | Iterative Verfeinerung | Bewertet und verbessert einen Entwurf; Mitarbeiter oder Fähigkeiten wie beim Prompt | Implementiert |
| `writeFile` | Datei schreiben | Schreibt einen explizit konfigurierten Wert als Datei | Implementiert |
| `readFile` | Datei lesen | Liest eine konkrete Datei-Version | Implementiert |
| `readEmail` | E-Mail lesen | Liest Absender, Betreff und Inhalt eines Events | Microsoft Graph implementiert |
| `readChannelEvent` | Nachricht lesen | Liest E-Mail-, WhatsApp-, SMS-, Telegram- oder Instagram-Events (außer E-Mail in der Palette deaktiviert, „Bald verfügbar“); der Nachrichtentext ist der Hauptwert, Absender, Betreff (nur E-Mail) und Ankunftszeit sind weitere Werte | Implementiert |
| `sendChannelMessage` | Nachricht senden | Sendet E-Mail, WhatsApp, SMS, Telegram oder Instagram (außer E-Mail nur Platzhalter in der Palette, deaktiviert) | Microsoft-Graph-Antworten implementiert |
| `notificationSend` | Push-Benachrichtigung senden | Sendet einen aufgelösten Text als Push-Benachrichtigung an alle Team-Mitglieder | Implementiert |
| `humanApproval` | Freigabe | Haltet den Run bis zur menschlichen Entscheidung an | Implementiert |
| `dialogInput` | Formulareingabe | Pausiert den Run und fragt typisierte Eingaben per Formular ab | Implementiert |
| `mediaInput` | Bild anfordern | Pausiert den Run und fordert ein Bild an; Quelle wird während der Ausführung gewählt; optional Dokumentenscanner (Android, iOS, Web) | Implementiert |
| `modelInference` | Modell ausführen | Modell per Suche im globalen Modellkatalog (plus eigene Modelle) wählen, eingrenzbar über Chips für Bereich, Aufgabe und Sprache; die Standalone-Runtime cacht es sofort im Hintergrund. Prüft explizite Workflow-Zuordnungen gegen das Manifest und führt ein ONNX-Modell aus | Backend-Pipeline implementiert; Runtime-Composition ausstehend |
| `textToSpeech` | Text vorlesen | Text-zu-Sprache über ein verbundenes Sprachmodell (Google AI, ElevenLabs, OpenAI-kompatibel, siehe [`sprachausgabe.md`](./sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Ausgabe | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `speechToText` | Audio transkribieren | Sprache-zu-Text über ein verbundenes Sprachmodell (Google AI, ElevenLabs Scribe, OpenAI-kompatibel, siehe [`sprachausgabe.md`](./sprachausgabe.md)) oder ein lokales ONNX-Modell mit Audio-Eingang | Implementiert; erste Audio-Modelle und -Transformationen folgen |
| `forEach` | Für jedes Element | Führt einen eingebetteten Arbeitsplan seriell für jedes Element eines JSON-Arrays aus | Implementiert |
| `documentLookup` | Datensatz suchen | Findet genau einen Datensatz über sichtbare Feldbedingungen | Lokale Runtime implementiert |
| `saveDocument` | Datensatz speichern | Legt ohne Bedingungen einen neuen Datensatz an; mit Feldbedingungen aktualisiert er alle Treffer oder legt bei keinem Treffer einen neuen an | Lokale Runtime implementiert |
| `tableFromCollection` | Sammlung als Tabelle | Liest eine Datensammlung vollständig und gibt sie als fachlichen Tabellen-Wert weiter; „Datei schreiben" speichert einen solchen Wert als `.xlsx` | Lokale Runtime implementiert |
| `readWebhook` | Webhook-Ereignis | Liest den Aufruf, der die Aufgabe über einen [Webhook](./webhooks.md) gestartet hat; liefert `value` (Inhalt), `method`, `query`, `headers`, `receivedAt` | Lokale Runtime implementiert |
| `shopware` | Shopware-Aktion | Eine Aktion eines Shopware-Shops (`config.action`, `connectionId`, `params`); jede Aktion erscheint als eigener Baustein, siehe [Integrationen](./integrationen.md) | Lokale Runtime; Aktionen: Bestellungen suchen/lesen, Bestellstatus ändern, Produkte suchen/ändern, Kunden suchen, Abfrage; siehe [Shopware](./shopware.md) |
| `httpRequest` | HTTP-Anfrage | Ruft die HTTP-API eines externen Systems auf, optional über eine gespeicherte [Verbindung](./verbindungen.md); liefert `value`, `status`, `ok`, `headers` | Lokale Runtime implementiert |
| `toolCall` | Werkzeug-Aufruf | Strukturierter Aufruf eines Werkzeugs | Geplant |
| `validation` | Validierung | Prueft Output gegen Schema oder Regeln | Geplant |

Die vollstaendigen Output-Slots dokumentiert
[`../node-executor-outputs.md`](../node-executor-outputs.md).

### Bausteine von Plugins

Ein Plugin bringt Bausteine mit, ohne den Kern zu ändern. Backend und Client haben je eine Seite:

- **Backend:** ein `NodeExecutor`, angemeldet an der `NodeExecutorRegistry`
  (`createDefaultNodeExecutorRegistry`). Die Konfiguration steht noch in `workflowPrimitives` und
  `nodeConfigSchema` (`task-definition.ts`); das ist je Primitive eine Zeile.
- **Client:** Die Konfiguration erbt von `PluginNodeConfig` (`task_builder/domain/entities/plugin_node_config.dart`)
  und liegt im Ordner des Plugins (`NodeConfig` ist bewusst nicht `sealed`). Sie liefert `typeId` (Kennung in Palette und
  Registry), `documentPrimitive` (Name im Backend und im Dokument; Vorgabe `typeId`, mehrere Aktionen können sich eines
  teilen), `toDocument()`, `primaryOutputType` und `secondaryOutputs` (Name → Typ). `TaskBuilderCubit.updatePluginNode`
  ändert sie ohne eigene Mutation. Ein `PluginNodeModule`
  (`task_builder/presentation/plugin_node_module.dart`) bündelt Titel, Beschreibung, Gruppe und Icon der Palette,
  Anfangskonfiguration, `fromDocument`, das Widget und optional `isAvailable`; `PluginNodeModules.register` meldet es
  beim Start an. Mapper, Palette, Canvas und Ausgaben-Anzeige brauchen dafür keine Änderung.

Der Kern kennt Plugin-Bausteine über den einen Enum-Wert `WorkflowPrimitive.plugin`. Ein gespeicherter Baustein, dessen
Plugin nicht (mehr) angemeldet ist, wird beim Laden zur Texteingabe; auf der Leinwand erscheint für Plugin-Bausteine
ohne Modul der Hinweis „Dieser Baustein ist nicht verfügbar“. Ein Beispiel liefert
`test/features/task_builder/plugin_node_test.dart`.

## Standardnamen neuer Bausteine

Die Namen der Werte (`outputs`), Titel und Beschreibung eines neuen Bausteins kommen aus
`NodeTextDefaults` (Port in `domain/services`, Umsetzung `LocalizedNodeTextDefaults`) und
folgen der App-Sprache **zum Zeitpunkt des Anlegens**. Sie werden im Task gespeichert; ein
späterer Sprachwechsel benennt nichts um, `{{…}}`-Referenzen bleiben stabil. Namen sind
ASCII (`pruefung`, nicht `prüfung`), weil `_normalizedOutputName` Nicht-`\w`-Zeichen entfernt.
Namen beginnen mit Großbuchstaben. Der erste Baustein einer Art trägt keine Nummer, ab dem zweiten zählt es ab 2 (nächster freier Name im Graphen): `Input`, `Input2` (en) / `Eingabe`, `Eingabe2` (de), `SendEmail` / `SendenEmail`.
Prompt-Bausteine heißen nach ihrem Ausgabetyp: Freitext „Text“, Entscheidung „Antwort“
(`decisionOutputBase`; en „Text“/„Answer“, tr „Metin“/„Cevap“). Beim Wechsel auf oder weg von
„Entscheidung“ wird der Hauptwert immer auf den Standardnamen des neuen Typs gesetzt (bei
Kollision nummeriert), auch wenn er vorher umbenannt war.

Ein direkt folgender Bedingter Ablauf ist nur lose an den Entscheidungs-Prompt gekoppelt
(`task_builder_decision_branch_mutations.dart`):
- Wird er leer hinter einem Entscheidungs-Prompt angehängt, bekommt er einmalig je Antwort einen
  Zweig mit sichtbarer Bedingung `{{Antwort}}` *ist gleich* `<Antwort>`.
- Regel: **Umbenennen zieht nach, alles andere ist sichtbar und manuell.**
  - Benennt man eine Antwort um, folgen Zweige, deren Bedingung noch genau
    `{{Antwort}}` *ist gleich* `<alte Antwort>` lautet (`withRenamedAnswer`); die Beschriftung
    folgt, solange sie der alten Antwort entspricht. Wer die Bedingung eines Zweigs ändert, löst
    ihn damit vom Prompt; er wird danach nicht mehr aktualisiert.
  - Benennt man den Hauptwert des Prompts um (auch automatisch beim Typwechsel), ziehen alle
    Bedingungen den Namen nach (`{{Antwort}}` → `{{Text}}`), damit sie gültig bleiben.
  - Neue oder gelöschte Antworten ändern den Ablauf nicht. Das Panel nennt Antworten ohne
    passenden Zweig (`missingDecisionAnswers`); „Fehlende Zweige ergänzen“ fügt sie vor
    „Sonst“ ein. Eigene Bedingungen und „Sonst“ bleiben immer.
Die technischen Schlüssel der Werte (z. B. `recipient`, `sender`) sind Datenvertrag und bleiben englisch; ihre Standardnamen stehen unter `task_builder.output_field_names`.

## UI-Prinzipien

- Das Aufgabenstudio übernimmt die Inter-Typografie und die abgestuften
  Oberflächen aus [`../DESIGN.md`](../DESIGN.md). `TaskBuilderTheme` bündelt
  diese Gestaltung für Hell- und Dunkelmodus innerhalb des Builders.
  Die gemeinsame Kopfzeile richtet Navigation über der Palette, den
  editierbaren Aufgabentitel über der Arbeitsfläche und KI-Agent sowie
  Benachrichtigungen rechts nebeneinander aus.
- Ausgabe-Labels zeigen Farbe und Icon ihres
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
  Darstellung ist reine UI. Die Suche bietet alle benannten Werte gleich an:
  Hauptwerte, weitere Werte (z. B. `{{Gefunden}}`) und Script-Variablen.
- Alle Werte eines Bausteins (Hauptwert, z. B. „Gefunden“ bei „Datensatz
  suchen“, und die Felder von strukturierter Prompt-Ausgabe, Dialogeingabe
  und Script mit `workflow_output`) sind `WorkflowOutput`s: graph-weit
  eindeutig, ab 2 nummeriert; Haupt- und weitere Werte heißen lokalisiert
  und großgeschrieben, Felder wie ihr Feldname. Das rechte Panel
  (`NodeOutputChips`) zeigt alle;
  Antippen benennt um (belegte Namen bekommen eine Nummer), das
  Kopier-Symbol kopiert `{{Name}}`, das Pin-Symbol (`OutputCanvasToggle`)
  legt fest, ob der Wert auch als Chip auf der Arbeitsfläche steht
  (`showOnCanvas`, Standard: Hauptwert und Felder). Auf der Arbeitsfläche lassen
  sich sichtbare Werte per Doppelklick umbenennen. Einzige Quelle dafür,
  welche Werte ein Baustein-Typ hat:
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
