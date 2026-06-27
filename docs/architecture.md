# Architecture

Cross-cutting Themen für Syscat. Feature-spezifische Inhalte liegen in
[`features/`](./features/).

## Schichten

```
┌────────────────────────────────────────────────────────┐
│ Presentation   (lib/features/*/presentation/)          │
│   Cubits / Pages / Widgets                             │
├────────────────────────────────────────────────────────┤
│ Domain          (lib/features/*/domain/)               │
│   Entities / Repository-Interfaces / UseCases          │
├────────────────────────────────────────────────────────┤
│ Infrastructure  (lib/features/*/infrastructure/)       │
│   Repository-Implementierungen (in-memory, Firestore)  │
└────────────────────────────────────────────────────────┘
```

Regel: Abhängigkeiten zeigen **nach innen**. Presentation darf Domain
referenzieren, Domain kennt weder Presentation noch Infrastructure, und
Infrastructure implementiert ausschließlich Domain-Interfaces.

## Datenmodell (Überblick)

| Entität             | Datei                                                                  | Rolle                            |
| ------------------- | ---------------------------------------------------------------------- | -------------------------------- |
| `TaskDefinition`    | `lib/features/task_builder/domain/entities/task_definition.dart`       | Aggregate Root eines Workflows   |
| `WorkflowNode`      | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Ein Baustein (Primitive-Instanz) |
| `WorkflowEdge`      | `lib/features/task_builder/domain/entities/workflow_edge.dart`         | Gerichtete Kante                 |
| `NodeId`            | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Value Object (`==` + `hashCode`) |
| `WorkflowPrimitive` | `lib/features/task_builder/domain/entities/workflow_node.dart`         | Enum der Bausteintypen           |

Detailtiefe pro Feature in [`features/aufgabe.md`](./features/aufgabe.md#domänenmodell).

## Persistenz

- **Aktuell:** `InMemoryTaskDefinitionRepository`. Überlebt keinen App-Restart.
- **Ziel:** Firestore. Eine Sammlung `tasks` pro Nutzer:in, ein Dokument pro
  `TaskDefinition`. Snapshot wird im Cubit zu Domain-Entität deserialisiert.
- **Migrationspfad:** Repository-Interface in `domain/repositories/` bleibt
  unverändert. In `infrastructure/repositories/` wird eine
  `FirestoreTaskDefinitionRepository` ergänzt; Bindung in `main.dart` /
  DI-Container.

## Auth & AppCheck

- Auth-Source: Firebase Auth (anzubinden).
- `onCallGenkit` unterstützt `authPolicy` (`hasClaim`, `isSignedIn`).
- `enforceAppCheck: true` aktivieren, sobald das erste Feature produktiv geht.
- Secrets (Modell-API-Key) ausschließlich via
  `defineSecret("GOOGLE_GENAI_API_KEY")`.

## Trigger-Modell (geplant)

| Trigger-Typ     | Quelle                    | Umsetzung                                  |
| --------------- | ------------------------- | ------------------------------------------ |
| Manuell         | UI-Button „Jetzt starten" | Direkter `onCallGenkit`                    |
| Zeitgesteuert   | Cloud Scheduler           | Pub/Sub → Genkit-Flow                      |
| Event           | Geräte- / Webhook-Event   | Firestore-Trigger oder HTTPS-Webhook       |
| Freigabe        | Mensch bestätigt          | Genkit-Interrupt + Task-Rückkanal          |

Detailtiefe in [`features/zeitplan.md`](./features/zeitplan.md), sobald das
Feature startet.

## Telemetrie

- `enableFirebaseTelemetry()` aus `@genkit-ai/firebase` aktivieren — Traces
  und Metrics landen in Google Cloud Observability.
- Im Client: `firebase_crashlytics` ergänzen, sobald produktiv.

## Genkit-Backend (allgemein)

### Konventionen für neue Flows

- Flow-Namen: `camelCase`, enden auf `Flow`.
- Datei: feature-spezifische Flows in `<feature>-workflows.ts`. Wenn der Flow
  keinem Feature zugeordnet ist (z. B. ein Querschnitts-Service), eigene
  gleichnamige Datei.
- **Schemas:** `inputSchema` / `outputSchema` mit **Zod** (`z.object(...)`).
  Keine `any`-Typen in der Schnittstelle.
- **Modell:** Standard `googleAI.model('gemini-2.5-flash')`. Andere Modelle
  begründen.
- **Export:** Jeder Flow wird in `functions/src/index.ts` re-exportiert.
- **Secrets:** Modell-API-Keys via `defineSecret` (`GOOGLE_GENAI_API_KEY`).
- **Streaming:** `streamSchema` setzen, wenn der Flow gestreamt werden soll.

### Vorhandene Flows

| Flow                          | Datei                            | Status                          |
| ----------------------------- | -------------------------------- | ------------------------------- |
| `runTaskDefinitionFlow`       | `functions/src/task-workflows.ts` | Produktiv (Feature Aufgabe)     |
| `conditionalTaskFlow`         | `functions/src/task-workflows.ts` | Produktiv (Feature Aufgabe)     |
| `iterativeRefinementTaskFlow` | `functions/src/task-workflows.ts` | Produktiv (Feature Aufgabe)     |
| `menuSuggestionFlow`          | `functions/src/genkit-sample.ts` | Vorlage — nicht produktiv       |

Feature-spezifische Detailtiefe (Inputs, Outputs, Temperatur) in
[`features/aufgabe.md`](./features/aufgabe.md#genkit-flows-aufgabenspezifisch).

### Neue Genkit-Tools

Eigene Tools unter `functions/src/tools/<domain>.ts` ablegen. Jeder Export
eines Tools wird über `ai.defineTool({...}, async (...) => {...})` registriert
und in dem jeweiligen Flow verwendet.
