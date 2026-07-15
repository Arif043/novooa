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
- Titel + Objective editieren und Aufgabe ausführen.
- Sofortige Persistenz via `TaskRepository.saveTask()` ohne Speichern-Button.
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
│   │   └── task_repository.dart              # Persistenz + Ausführung
│   └── usecases/
│       └── execute_task.dart                 # Task ausführen + tracken
├── infrastructure/
│   ├── models/
│   │   └── task_document_mapper.dart          # Firestore-Serialisierung
│   └── repositories/
│       └── firebase_task_repository.dart      # Firestore + Callable Function
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
5. **Persistenz nach jeder Mutation.** Der Cubit ruft beim Öffnen und nach
   jeder Änderung `TaskRepository.saveTask()` auf — kein „später speichern".

## Primitives

| Enum-Wert               | UI-Label (de)                | Beschreibung                                                 | Genkit-Mapping                                       |
| ----------------------- | ---------------------------- | ------------------------------------------------------------- | ---------------------------------------------------- |
| `stringInput`           | **Texteingabe**              | Gibt einen festen String als Output weiter                    | Direkter Runner-Output                               |
| `script`                | **Script**                   | Führt Python-Code mit Vorgänger-Output als `input` aus        | Interner `executeScriptNode`                         |
| `prompt`                | **Prompt**                   | LLM-Aufruf mit Vorlage und Variablen                          | Interner `executePromptNode`                          |
| `conditionalFlow`       | **Bedingter Ablauf**         | Verzweigt anhand eines Prädikats auf den vorherigen Output   | Interner `executeConditionalNode`                     |
| `iterativeRefinement`   | **Iterative Verfeinerung**   | Draft → Critique → Improve, n Runden                          | Interner `executeIterativeRefinementNode`             |
| `writeFile`             | **Datei schreiben**          | Schreibt den Vorgänger-Output als Datei                       | Interner `executeWriteFileNode`                       |
| `readFile`              | **Datei lesen**              | Liest eine ausgewählte Datei-Version als String                | Interner `executeReadFileNode`                        |
| `readEmail`             | **E-Mail lesen**             | Liest Absender, Betreff, Nachricht und Ankunftszeit aus dem Run-Event | Interner `executeReadEmailNode`                |
| `toolCall`              | **Werkzeug-Aufruf**          | Strukturierte Tool-Invocation (z. B. Suche, E-Mail, Kalender) | `ai.generate({tools: […]})`                           |
| `humanApproval`         | **Freigabe**                 | Hält den Flow an, bis ein Mensch bestätigt                    | Interner `executeHumanApprovalNode`                   |
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
│ BuilderPanel — Titel, Objective, Ausführen                           │
└──────────────────────────────────────────────────────────────────────┘
```

### UX-Prinzipien

1. **Autosave statt Speichern-Dialog.** Änderungen werden unter der Haube
   gespeichert; die UI bietet keinen Speichern-Button an.
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

## Genkit-Ausführung (aufgabenspezifisch)

Datei: `functions/src/task-workflows.ts`. Nur `runTaskDefinitionFlow` wird in
`functions/src/index.ts` re-exportiert. Einzelne Bausteine werden über interne
Executor unter `functions/src/task-executors/` ausgeführt. Der Graph-Runner
kennt keine primitive-spezifische `switch`-Logik mehr, sondern delegiert über
`functions/src/task-runner/node-executor-registry.ts` an `NodeExecutor`-
Strategien.

### Model-Provider

Standardmäßig nutzt der Backend-Flow Gemini über `@genkit-ai/google-genai`.
Alternativ kann MiniMax über den OpenAI-kompatiblen Genkit-Provider aktiviert
werden. Dafür müssen beim Start der Functions diese Umgebungsvariablen gesetzt
sein:

```bash
AI_PROVIDER=minimax
MINIMAX_API_KEY=...
MINIMAX_BASE_URL=...
MINIMAX_MODEL=...
```

`MINIMAX_BASE_URL` ist absichtlich nicht hart codiert, weil MiniMax je nach
Region und Produkt unterschiedliche OpenAI-kompatible Endpunkte verwenden kann.
Die Executors beziehen ihre Modelle zentral aus
`functions/src/task-runner/ai-models.ts`.

### Prompt-Executor

Datei: `functions/src/task-executors/prompt-node-executor.ts`.
`executePromptNode` ist bewusst kein exportierter Genkit-Flow, sondern ein
interner Executor-Schritt von `runTaskDefinitionFlow`.

```ts
input:  { instruction: string; context: string; outputType: "text" | "decision" | "structured"; choices: string[]; structuredFields: StructuredOutputField[] }
output: { answer: string; outputs: Record<string, NodeOutputValue> }
```

Temperatur: `0.3`. Streamt nicht.

Wenn ein Node Dateien oder Wissensnotizen anhängt, bereitet der Graph-Runner
den Workspace vor dem Executor-Aufruf über
`functions/src/task-runner/node-attachment-workspace.ts` vor:

1. Storage-Objekte aus `attachments[].storagePath` herunterladen.
2. Wissensnotizen aus Firestore unter
   `teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}` laden.
3. MOC-Notizen rekursiv über `outgoingLinks` auflösen.
4. Alles in ein temporäres, node-spezifisches Verzeichnis unter `/tmp`
   schreiben.
5. Den vorbereiteten Workspace an den jeweiligen `NodeExecutor` übergeben.
6. Das temporäre Verzeichnis nach dem Node-Aufruf wieder entfernen.

Prompt-Nodes verwenden den Workspace über
`functions/src/task-runner/node-attachment-genkit.ts` mit
`filesystem({ rootDirectory })` aus `@genkit-ai/middleware`. Dieselbe Datei
stellt außerdem die gemeinsame `retry`-Middleware für alle Genkit-Model-Turns
bereit. Transiente Fehler wie `UNAVAILABLE`, `DEADLINE_EXCEEDED`,
`RESOURCE_EXHAUSTED`, `ABORTED` und `INTERNAL` werden mit exponentiellem
Backoff wiederholt.

Die Filesystem-Middleware läuft read-only. Das Modell erhält im Prompt eine
Liste der lokalen Dateinamen und Wissensnotizen und kann über `list_files` /
`read_file` auf die Inhalte zugreifen. Wissensnotizen liegen unter
`knowledge/`; eine Übersicht liegt in `knowledge/manifest.json`.

Variablen aus vorherigen Script-Bausteinen können in Prompt-Anweisungen und
Entscheidungsoptionen über `{{name}}` referenziert werden. Für Objekte und
Listen werden Dot-Pfade unterstützt, z.B. `{{kunde.name}}` oder
`{{rechnungen.0.betrag}}`. Nicht gefundene Variablen bleiben unverändert im
Prompt sichtbar.

Aktuell sind Wissensbasis-Anhänge nur für Prompt-Bausteine aktiv. Script-
Bausteine verwenden weiterhin ausschließlich Dateianhänge.

### Script-Executor

Datei: `functions/src/task-executors/script-node-executor.ts`.
Der Script-Node führt Python-Code aus. Der Output des Vorgänger-Nodes wird im
Script als Variable `input` bereitgestellt; das Script muss eine
String-Variable `output` setzen.

```python
output = input.upper()
```

```ts
input:  { input: string; script: string }
output: string
```

Der MVP setzt ein Timeout von 5 Sekunden und begrenzt den Output auf 10 KB.
Es gibt keinen zusätzlichen Run-Kontext für Script-Nodes.

Wenn ein Script-Node Dateien anhängt, erhält der Python-Runtime-Scope diese
zusätzlichen Werte:

```python
files        # Liste der angehängten Datei-Metadaten
files_dir    # temporäres Arbeitsverzeichnis
list_files() # gibt files zurück
read_file(name) # liest eine angehängte Datei per filename/displayName/id
```

Beispiel:

```python
erste_datei = files[0]["filename"]
output = read_file(erste_datei)
```

Variablen, die ein Script deklariert, bleiben für den weiteren Task-Run
verfügbar. Spätere Script-Nodes erhalten diese Variablen wieder direkt im
Python-Scope:

```python
name = "Ada"
output = name
```

```python
output = input + " " + name
```

Andere Node-Typen erhalten die aktuellen Variablen als Kontexttext. Der
Variablen-Scope gilt pro Task-Ausführung und wird nicht als globaler Zustand
zwischen verschiedenen Runs persistiert.

### `runTaskDefinitionFlow`

Startet eine gespeicherte Aufgabe im Hintergrund. Der Client sendet nur die
`taskId`; der Flow lädt die `TaskDefinition` über die Callable-Auth aus
Firestore unter `teams/personal_<uid>/tasks/{taskId}`, erzeugt einen
`taskRuns/{runId}`-Datensatz und gibt sofort die `runId` zurück. Ein
Firestore-Trigger führt den Run anschließend asynchron aus. Dabei interpretiert
der Worker den Graph, ermittelt ausführbare Knoten topologisch und delegiert an
den registrierten `NodeExecutor` des jeweiligen Primitives. Noch nicht
implementierte Bausteine werden als `skipped` markiert und liefern keine
Outputs.

```ts
input:  { taskId: string; context?: string }
output: { runId: string; taskId: string; status: "queued" }
```

`NodeExecutionResult` enthält `nodeId`, `primitive`, `status`, `outputs`,
optional `selectedNodeId` und optional `message`. Nodes liefern ihre Ergebnisse
ausschließlich als benannte Werte in `outputs`:

```ts
outputs: Record<string, { type: "string" | "datetime" | "number" | "boolean" | "json", value: unknown }>
```

Beispiel `readEmail`:

```ts
outputs: {
  text: { type: "string", value: "..." },
  sender: { type: "string", value: "kunde@example.com" },
  subject: { type: "string", value: "Anfrage" },
  message: { type: "string", value: "..." },
  receivedAt: { type: "datetime", value: "2026-07-14T10:15:00.000Z" }
}
```

Mögliche Node-Status sind `executed`, `skipped` und `waitingForApproval`.

`WorkflowNode` nutzt ein generisches `config`-Objekt. Die konkrete Struktur
wird über `config.primitive` bestimmt. Jeder Node besitzt zusätzlich einen
eindeutigen `referenceName`, über den spätere Template-Felder auf Outputs dieses
Nodes zugreifen können:

```text
{{email1.sender}}
{{email1.subject}}
```

Globale Task-Variablen bleiben ohne Prefix:

```text
{{kunde}}
```

Die Template-Ersetzung erfolgt zentral im `TaskRunContext` und wird von
textbasierten Executor-Feldern genutzt, darunter String-Eingabe, Prompt,
Script, Datei schreiben, Freigabe, Verzweigung und iterative Verfeinerung.

Für Script-Bausteine:

```ts
{
  primitive: "script",
  script: string,
  attachments: NodeAttachment[]
}
```

Für Prompt-Bausteine:

```ts
{
  primitive: "prompt",
  instruction: string,
  outputType: "text" | "decision" | "structured",
  firstChoice: string,
  secondChoice: string,
  structuredFields: { name: string; description: string }[],
  attachments: NodeAttachment[]
}
```

Bei `outputType: "structured"` erzeugt der Executor ein required Zod-Object.
Alle definierten Felder müssen vom Modell gefüllt werden. Jedes Feld wird als
benannter Node-Output gespeichert; zusätzlich wird die komplette Struktur als
JSON in `outputs.text` abgelegt.

Für Freigabe-Bausteine:

```ts
{
  primitive: "humanApproval",
  instruction: string,
  reviewScope: "currentInput" | "executionTrace"
}
```

Für Datei-schreiben-Bausteine:

```ts
{
  primitive: "writeFile",
  fileName: string,
  contentType: string,
  fileId?: string
}
```

Der Baustein nimmt den Output des Vorgänger-Nodes als String, schreibt ihn als
UTF-8-Datei nach Firebase Storage und erzeugt die Datei-Metadaten unter
`teams/{teamId}/files/{fileId}`. Ist `fileId` gesetzt, schreibt der Baustein
eine neue Version dieser Datei und aktualisiert `currentVersionId` am
Datei-Dokument. Ohne intern gesetzte `fileId` erzeugt er eine neue Datei mit
erster Version, falls im Root-Dateibereich des Teams noch keine Datei mit
demselben Namen existiert. Existiert dort bereits eine Datei mit demselben
`displayName`, schreibt der Baustein implizit eine neue Version dieser Datei.
Die UI zeigt dafür kein manuelles Datei-ID-Feld. Der Node-Output ist ein
JSON-String mit `fileId`, `versionId`, `storagePath`, `displayName`,
`contentType` und `sizeBytes`.

Die UI startet ohne ausgewählte Ausgabedatei. Der Baustein zeigt ein
Klickfeld, das einen Dialog öffnet. Dort kann eine bestehende Team-Datei als
Ziel gewählt oder eine neue Datei mit Dateiname und optionalem Content-Type
definiert werden. Datei-IDs bleiben ein internes Detail.

Für Datei-lesen-Bausteine:

```ts
{
  primitive: "readFile",
  file?: NodeAttachment
}
```

Der Baustein referenziert eine konkrete Datei-Version über `NodeAttachment`,
lädt den zugehörigen Storage-Pfad und gibt den UTF-8-Inhalt als String aus.
Wenn keine Datei ausgewählt ist, schlägt der Baustein mit einer fachlichen
Fehlermeldung fehl.

Freigabe-Bausteine sind immer harte Kontrollpunkte: Review ist Pflicht,
Bearbeitung des Outputs ist immer erlaubt, Ablehnung ist immer erlaubt und eine
Ablehnung verwirft den gesamten TaskRun. Wenn ein Run einen Freigabe-Baustein
erreicht, beendet die Cloud Function die aktuelle Invocation kontrolliert mit
dem Run-Status `waitingForApproval`. Der Zwischenzustand wird im
`taskRuns/{runId}`-Dokument unter `resumeState` gespeichert:

```ts
{
  nodeResults: NodeExecutionResult[],
  variables: Record<string, unknown>,
  remainingNodeIds: string[],
  skippedNodeIds: string[],
  waitingNodeId: string
}
```

Noch nicht ausgeführte Nodes werden nicht als `skipped` markiert. Der spätere
Approve/Reject-Kanal setzt bei `resumeState` an: Freigabe ersetzt den Output des
wartenden Nodes und führt den Graph weiter; Ablehnung verwirft den ausführbaren
Zwischenzustand und markiert den Run als `rejected`. Für die UI werden zusätzlich
`reviewInstruction` und `reviewOutput` am Run-Dokument gespeichert. Bei
pausierten Runs werden `nodeResults` nur in `resumeState` gespeichert. Die
Top-Level-`nodeResults` werden erst bei vollständig abgeschlossenen Runs
geschrieben.

```ts
reviewTaskRunFlow:
input:  { runId: string; decision: "approve" | "reject"; output?: string }
output: { runId: string; status: "queued" | "rejected" }
```

Dateianhänge referenzieren eine konkrete Storage-Version:

```ts
{
  id: string,
  storagePath: string,
  generation: string,
  displayName: string,
  contentType: string,
  sizeBytes: number
}
```

### Node-Executor-Registry

Dateien:

- `functions/src/task-runner/node-executor.ts`
- `functions/src/task-runner/node-executor-registry.ts`
- `functions/src/task-executors/*-node-executor.ts`

Jeder ausführbare Baustein implementiert die `NodeExecutor`-Strategy:

```ts
type NodeExecutor = {
  primitive: WorkflowNode["primitive"];
  execute(
    input: NodeExecutorInput,
    runContext: TaskRunContext
  ): Promise<NodeExecutionResult>;
}
```

Der Graph-Runner bleibt für Topologie, Skip-Logik, Trail-/Fehler-Logging und
Subgraph-Orchestrierung zuständig. Primitive-spezifische Logik lebt im
jeweiligen Executor. Conditional-Branches erhalten einen injizierten
`runSubgraph`-Callback, damit der Conditional-Executor keine direkte
Abhängigkeit auf den Graph-Runner hat.

Architektur-Notiz: `context` soll nicht dauerhaft als Sammelbegriff für
Run-Input, Parent-Outputs und Node-Input dienen. Der nächste sinnvolle Schritt
ist ein expliziteres `NodeExecutionInput`:

```ts
type NodeExecutionInput = {
  node: WorkflowNode,
  input: string,
  parentResults: NodeExecutionResult[],
  attachmentWorkspace?: NodeAttachmentWorkspace
}
```

Der `TaskRunContext` bleibt separat und enthält übergreifenden Run-Zustand wie
`task`, `teamId`, `input`, `variables`, `results` und `runSubgraph`.
`input` enthält strukturierte Startdaten des Runs, z. B. ein
`emailReceived`-Event, das der Baustein `readEmail` in benannte Outputs
übersetzt. Ziel: Jeder Node bekommt einen klaren fachlichen Input, kennt bei
Bedarf seine direkten Vorgängerergebnisse und greift getrennt auf Run-weite
Variablen zu.

### Activity-Tracking

Activity-Tracking passiert serverseitig während des Hintergrund-Runs. Pro
Ausführung entstehen unter `teams/{teamId}/activities/{activityId}`:

- eine Task-Aktivität `started` mit Run-ID und Eingabekontext,
- pro Baustein eine Node-Aktivität mit Status `succeeded`, `skipped` oder
  `waiting`,
- eine abschließende Task-Aktivität `succeeded` oder `failed`, sofern der Run
  nicht auf Freigabe wartet.

Der Flutter-Client startet nur den Run und wartet nicht auf Node-Ergebnisse.
Die Aktivitäten-Seite liest die Firestore-Logs über das Feature
„Aktivitäten".

### Lokale Ausführung aus Flutter

Der Flutter-Client ruft `runTaskDefinitionFlow` als Firebase Callable Function
auf. Für lokale Tests wird nur der Firebase Emulator gestartet; der Client wird
per `USE_FIREBASE_EMULATORS` auf Auth, Firestore und Functions umgebogen:

```bash
npm --prefix functions run serve
flutter run --dart-define=USE_FIREBASE_EMULATORS=true
```

Die App verwendet damit dieselbe Callable-Function-Implementierung wie in
Production. Es gibt keinen separaten lokalen Genkit-Reflection-Server oder
CORS-Proxy mehr.

### Conditional-Executor

Datei: `functions/src/task-executors/conditional-node-executor.ts`.
`executeConditionalNode` erhält als Eingabe das Ziellabel aus dem direkten
Vorgänger-Output, typischerweise von einem `prompt` mit `outputType:
"decision"`. Der Executor wählt primär den Branch, dessen Label exakt dem
Ziellabel entspricht. Der Graph-Runner führt anschließend den `graph` dieses
Branches als Subgraph aus und verwendet dessen finale Ausgabe als Output des
Conditional-Knotens. Ohne Match fällt der Executor auf den ersten Branch
zurück. Ausgehende Top-Level-Kanten bleiben nur als Legacy-Fallback erhalten.

```ts
input:  { node: WorkflowNode; targetLabel: string; outgoingEdges: WorkflowEdge[] }
output: { selectedBranchId?: string | null; selectedBranchLabel?: string | null; selectedNodeId: string | null; reason: string }
```

### Iterative-Refinement-Executor

Datei:
`functions/src/task-executors/iterative-refinement-node-executor.ts`.
`executeIterativeRefinementNode` folgt dem Genkit-Pattern „Hybrid: Iterative
refinement": Ein Evaluator bewertet pro Runde den vorhandenen `draft` mit
`{ critique, satisfied }`, und der Optimizer verbessert den Entwurf anhand des
Feedbacks. Die Schleife endet, sobald `satisfied` wahr ist oder
`maxIterations` erreicht wurde. Bei OpenAI-kompatiblen Providern wird ein
Text-JSON-Fallback verwendet, falls strukturierte Evaluation nicht validiert.
Der Node besitzt keinen internen Prompt-Graph mehr. Der Runner verwendet die
Ausgabe des vorherigen Nodes als `draft` und verfeinert diese mit
`optimizerPrompt`, `critiquePrompt` und `maxIterations`.

```ts
input:  { objective: string; draft: string; optimizerPrompt: string; critiquePrompt: string; maxIterations: 1..5 }
output: { answer: string; iterations: number }
```

Verbesserungstemperatur: `0.4`. Streamt nicht.

## Definition of Done

- [ ] Nutzer:in kann Bausteine aus der Palette per Drag-and-Drop auf die
      Leinwand ziehen.
- [ ] Knoten können verbunden, selektiert, gelöscht und verschoben werden.
- [ ] NodeInspector zeigt sinnvolle Felder pro Primitive und persistiert
      Änderungen sofort.
- [ ] BuilderPanel erlaubt Titel + Objective zu editieren.
- [ ] `TaskRepository.saveTask()` wird nach jeder Mutation aufgerufen; der Cubit
      emittiert einen neuen `TaskBuilderLoaded`-State.
- [ ] Leere Zustände und Fehlerzustände sind auf Deutsch formuliert.
- [ ] `flutter analyze` ist sauber.
- [ ] `npm --prefix functions run build` ist sauber.
- [ ] Mindestens ein Smoke-Test für `TaskBuilderCubit` (Hinzufügen eines
      Knotens → Liste wächst, Kante wird erzeugt).

## Offene Fragen

- **Persistenz:** Firestore-Modell ist unter `teams/{teamId}/tasks/{taskId}`
  angebunden; aktuell nutzt der Client `personal_<uid>` als Team-Kontext.
- **Tool-Registry:** Wo leben konkrete Tools (siehe
  [`../architecture.md#neue-genkit-tools`](../architecture.md#neue-genkit-tools)).
- **Visualisierung:** Canvas-Implementierung — Start mit `InteractiveViewer` +
  `CustomPaint`, Migration zu dedizierter Lib erst bei Undo/Redo +
  Multi-Select + Auto-Layout.
