# Feature: Aufgabe

> Der Task Builder — das Herzstück von Syscat. Nutzer:innen bauen
> Automatisierungen aus Bausteinen zusammen.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`arbeitsplaene.md`](./arbeitsplaene.md) ·
[`zeitplan.md`](./zeitplan.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Visualisierung und Bearbeitung von `TaskDefinition`-Aggregaten. Drag-and-Drop
von Bausteinen auf eine Leinwand, Bearbeitung pro Knoten, Persistenz nach jeder
Mutation.

## Verantwortlichkeiten

- Bausteine aus der Palette per Drag-and-Drop auf die Leinwand ziehen.
- Knoten selektieren, löschen, verschieben, verbinden.
- Pro Primitive typsichere Felder im NodeInspector anbieten.
- BuilderPanel: Titel + Objective editieren; Speichern / Ausführen.
- Sofortige Persistenz via `SaveDraftTaskDefinition`.
- Deutsche UI-Strings.

## Domänenmodell (Clean Architecture)

```
features/task_builder/
├── domain/
│   ├── entities/
│   │   ├── task_definition.dart   # Aggregate Root
│   │   ├── workflow_node.dart     # Knoten (Primitive-Instanz)
│   │   └── workflow_edge.dart     # Gerichtete Kante
│   ├── repositories/
│   │   └── task_definition_repository.dart   # Interface
│   └── usecases/
│       ├── get_draft_task_definition.dart     # aktuellen Entwurf laden
│       └── save_draft_task_definition.dart    # Entwurf persistieren
├── infrastructure/
│   └── repositories/
│       └── in_memory_task_definition.dart     # Default-Implementierung
└── presentation/
    ├── cubits/
    │   ├── task_builder_cubit.dart            # ChangeNotifier
    │   └── task_builder_state.dart            # sealed states
    ├── pages/
    │   └── task_builder_page.dart
    └── widgets/
        ├── primitive_palette.dart             # linke Spalte
        ├── workflow_canvas.dart               # mittlere Spalte
        ├── node_inspector.dart                # rechte Spalte
        └── builder_panel.dart                 # Komposition oben
```

### Domänen-Invarianten

`TaskDefinition` ist ein **immutable Aggregate Root**. Jede Mutation
(`selectNode`, `addNode`, …) liefert eine **neue Instanz** über `copyWith`.

1. **Immutability.** Kein `set`-Aufruf, kein versteckter State.
2. **IDs sind stabil.** `NodeId` ist ein Value-Object mit `==`/`hashCode`.
3. **Eine Selected Node.** Höchstens ein Knoten ist `selectedNodeId`.
4. **Edges referenzieren existierende Knoten.** Beim Hinzufügen muss die
   Quell-Kante existieren oder `addNode` fügt eine implizite Kante aus der
   aktuellen Selection ein.
5. **Persistenz nach jeder Mutation.** Der Cubit ruft nach jeder Aktion
   `SaveDraftTaskDefinition` auf — kein „später speichern".

## Primitives

| Enum-Wert               | UI-Label (de)                | Beschreibung                                                 | Genkit-Mapping                                       |
| ----------------------- | ---------------------------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| `prompt`                | **Prompt**                   | LLM-Aufruf mit Vorlage und Variablen                          | Interner `executePromptNode`                          |
| `conditionalFlow`       | **Bedingter Ablauf**         | Verzweigt anhand eines Prädikats auf den vorherigen Output   | `conditionalTaskFlow`                                 |
| `iterativeRefinement`   | **Iterative Verfeinerung**   | Draft → Critique → Improve, n Runden                          | `iterativeRefinementTaskFlow`                         |
| `toolCall`              | **Werkzeug-Aufruf**          | Strukturierte Tool-Invocation (z. B. Suche, E-Mail, Kalender) | `ai.generate({tools: […]})`                           |
| `humanApproval`         | **Freigabe**                 | Hält den Flow an, bis ein Mensch bestätigt                    | Custom Genkit-Interrupt / Firebase-Task               |
| `validation`            | **Validierung**              | Schema- / Wertebereichsprüfung auf Output eines Knotens       | `z.object(...).safeParse()`                           |

Beim Erweitern der Enum müssen Label, Beschreibung und Genkit-Mapping
synchron ergänzt werden — die `WorkflowPrimitiveLabels`-Extension in
`workflow_primitive_labels.dart` liefert für jeden Wert einen `label` und
`description`-Zweig.

## UI-Layout

```
┌──────────────────────────────────────────────────────────────────────┐
│ RootAppBar — Titel des aktuellen Tabs (z. B. „Aufgaben")            │
├──────────────┬────────────────────────────────────────┬──────────────┤
│              │                                        │              │
│ Primitive    │   WorkflowCanvas                       │   Node       │
│ Palette      │   • Drag-Target                        │   Inspector  │
│ (Bausteine)  │   • Drag-Source von Bausteinen         │   • Felder   │
│              │   • Selektion + Mehrfachauswahl        │     des      │
│              │   • Zoom/Pan (später)                  │     Knotens  │
│              │   • Auto-Layout (später)               │              │
│              │                                        │              │
├──────────────┴────────────────────────────────────────┴──────────────┤
│ BuilderPanel — Titel, Objective, Speichern, Ausführen                │
└──────────────────────────────────────────────────────────────────────┘
```

### UX-Prinzipien

1. **Eine sichtbare Hauptaktion pro Bildschirm.** „Speichern" ist die einzige
   primäre Aktion im BuilderPanel; alles andere ist sekundär.
2. **Anlass statt Konfiguration.** Jeder Knoten beginnt mit einer natürlich
   klingenden Frage („Wann soll das passieren?" / „Was soll passieren?"),
   nicht mit einem Properties-Grid.
3. **Inline-Vorschau.** Wo möglich, zeigt der NodeInspector eine Live-Vorschau
   auf den erzeugten Genkit-Code / die nächste Eingabe.
4. **Sofortiges Feedback.** Hinzufügen / Verschieben / Verbinden eines Knotens
   erzeugt eine kurze Bestätigung (Snackbar oder Haptik).
5. **Leere Zustände erzählen etwas.** „Ziehe deinen ersten Baustein auf die
   Leinwand, um zu starten" — keine reinen Lade-Spinner ohne Kontext.
6. **Glasklar.** `SyscatTheme.glassPanelDecoration` und `SyscatBackground`
   verwenden.

## Genkit-Flows (aufgabenspezifisch)

Datei: `functions/src/task-workflows.ts`. Die Flows werden in
`functions/src/index.ts` re-exportiert.

### Prompt-Executor

Datei: `functions/src/task-executors/prompt-node-executor.ts`.
`executePromptNode` ist bewusst kein exportierter Genkit-Flow, sondern ein
interner Executor-Schritt für den späteren `runTaskDefinitionFlow`.

```ts
input:  { instruction: string; context: string; outputType: "text" | "decision"; choices: string[] }
output: { answer: string }
```

Temperatur: `0.3`. Streamt nicht.

### `runTaskDefinitionFlow`

Führt eine komplette `TaskDefinition` aus. Der Flow interpretiert den Graph,
ermittelt ausführbare Knoten topologisch und delegiert Prompt-Knoten an
`executePromptNode`. Noch nicht implementierte Bausteine werden als `skipped`
markiert und reichen den bisherigen Kontext weiter.

```ts
input:  { taskDefinition: TaskDefinition; context?: string }
output: { taskId: string; finalOutput: string; nodeResults: NodeExecutionResult[] }
```

`NodeExecutionResult` enthält `nodeId`, `primitive`, `status`, `output` und
optional `message`.

### `conditionalTaskFlow`

Wählt aus einer Liste von `(nodeId, condition)`-Paaren den ersten Knoten, dessen
Bedingung im Kontext-String vorkommt (Substring-Match). Fallback auf
`fallbackNodeId`.

```ts
input:  { context: string; branches: { nodeId: string; condition: string }[]; fallbackNodeId: string }
output: { selectedNodeId: string; reason: string }
```

### `iterativeRefinementTaskFlow`

Iteriert `maxIterations` Mal (1–5, default 2): ruft `gemini-2.5-flash` mit
einem kombinierten Prompt aus Objective / Draft / Critique-Kriterien auf,
schreibt den Draft mit der Modell-Antwort überschrieben weiter.

```ts
input:  { objective: string; draft: string; critiquePrompt: string; maxIterations: 1..5 }
output: { answer: string; iterations: number }
```

Temperatur: `0.4`. Streamt nicht.

## Definition of Done

- [ ] Nutzer:in kann Bausteine aus der Palette per Drag-and-Drop auf die
      Leinwand ziehen.
- [ ] Knoten können verbunden, selektiert, gelöscht und verschoben werden.
- [ ] NodeInspector zeigt sinnvolle Felder pro Primitive und persistiert
      Änderungen sofort.
- [ ] BuilderPanel erlaubt Titel + Objective zu editieren und zu speichern.
- [ ] `SaveDraftTaskDefinition` wird nach jeder Mutation aufgerufen; der Cubit
      emittiert einen neuen `TaskBuilderLoaded`-State.
- [ ] Leere Zustände und Fehlerzustände sind auf Deutsch formuliert.
- [ ] `flutter analyze` ist sauber.
- [ ] `npm --prefix functions run build` ist sauber.
- [ ] Mindestens ein Smoke-Test für `TaskBuilderCubit` (Hinzufügen eines
      Knotens → Liste wächst, Kante wird erzeugt).

## Offene Fragen

- **Persistenz:** Firestore-Modell (siehe
  [`../architecture.md#persistenz`](../architecture.md#persistenz)).
- **Tool-Registry:** Wo leben konkrete Tools (siehe
  [`../architecture.md#neue-genkit-tools`](../architecture.md#neue-genkit-tools)).
- **Visualisierung:** Canvas-Implementierung — Start mit `InteractiveViewer` +
  `CustomPaint`, Migration zu dedizierter Lib erst bei Undo/Redo +
  Multi-Select + Auto-Layout.
- **Freigabe:** Wie genau pausiert `humanApproval`? Genkit-Interrupt vs.
  externer Task-Rückkanal.
