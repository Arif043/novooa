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

- Aufgaben werden in Firestore unter `users/{uid}/tasks/{taskId}` gespeichert.
- Der Task Builder arbeitet mit Autosave: Beim Öffnen einer neuen Aufgabe und
  nach jeder Mutation ruft der Cubit `TaskRepository.saveTask()` auf.
- Es gibt keinen expliziten Speichern-Button. Nutzer:innen müssen den
  Persistenzzeitpunkt nicht selbst verwalten.
- `TaskRepository` bündelt Entwurfs-Persistenz und Ausführung. Die konkrete
  Implementierung `FirebaseTaskRepository` speichert in Firestore und ruft für
  die Ausführung die Firebase Callable Function über `TaskRunnerDatasource` auf.
- Firestore-Dokumente enthalten `id`, `title`, `objective`, `selectedNodeId`,
  `graph`, `createdAt` und `updatedAt`.

### Teams und Dateien

Dateien sind von Beginn an team-scoped modelliert, auch wenn aktuell nur ein
persönlicher Arbeitsbereich verwendet wird.

Firestore:

```text
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/files/{fileId}
teams/{teamId}/files/{fileId}/versions/{versionId}
```

Storage:

```text
teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}
```

Der aktuelle Client erzeugt für angemeldete Nutzer:innen automatisch:

```text
teams/personal_<uid>
teams/personal_<uid>/members/<uid>
```

Das spätere Team-Feature ersetzt nur die Quelle für `teamId`: statt
`personal_<uid>` wird der aktive Team-Kontext verwendet. Datei-Metadaten und
Storage-Pfade bleiben unverändert.

Copy-on-Write wird über `versions/{versionId}` vorbereitet. Eine neue
Dateiversion schreibt ein neues Storage-Objekt und aktualisiert am
Datei-Dokument `currentVersionId`.

Detailtiefe in [`features/dateien.md`](./features/dateien.md).

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
| `menuSuggestionFlow`          | `functions/src/genkit-sample.ts` | Vorlage — nicht produktiv       |

Feature-spezifische Detailtiefe (Inputs, Outputs, Executor-Registry) in
[`features/aufgabe.md`](./features/aufgabe.md#genkit-ausführung-aufgabenspezifisch).

### Neue Genkit-Tools

Eigene Tools unter `functions/src/tools/<domain>.ts` ablegen. Jeder Export
eines Tools wird über `ai.defineTool({...}, async (...) => {...})` registriert
und in dem jeweiligen Flow verwendet.
