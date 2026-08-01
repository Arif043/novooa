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
| `script` | Script | Fuehrt Python mit Vorgaengeroutput aus | Implementiert |
| `prompt` | Prompt | LLM-Aufruf mit Vorlage und Variablen | Implementiert |
| `conditionalFlow` | Bedingter Ablauf | Verzweigt anhand eines Labels | Implementiert |
| `iterativeRefinement` | Iterative Verfeinerung | Bewertet und verbessert einen Entwurf | Implementiert |
| `writeFile` | Datei schreiben | Schreibt den Vorgaengeroutput als Datei | Implementiert |
| `readFile` | Datei lesen | Liest eine konkrete Datei-Version | Implementiert |
| `readEmail` | E-Mail lesen | Liest Absender, Betreff und Inhalt eines Events | Event-Lesen implementiert; Connectoren geplant |
| `readChannelEvent` | Nachricht lesen | Liest E-Mail-, WhatsApp- oder SMS-Events | Implementiert |
| `sendChannelMessage` | Nachricht senden | Sendet E-Mail, WhatsApp oder SMS | Implementiert; Kundenpostfach-Antworten geplant |
| `humanApproval` | Freigabe | Haltet den Run bis zur menschlichen Entscheidung an | Implementiert |
| `toolCall` | Werkzeug-Aufruf | Strukturierter Aufruf eines Werkzeugs | Geplant |
| `validation` | Validierung | Prueft Output gegen Schema oder Regeln | Geplant |

Die vollstaendigen Output-Slots dokumentiert
[`../node-executor-outputs.md`](../node-executor-outputs.md).

## UI-Prinzipien

- Autosave statt Speichern-Dialog.
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
