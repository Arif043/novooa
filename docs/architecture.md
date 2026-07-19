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

Die lokale Runtime folgt demselben Prinzip auf Backend-Seite: Task Runner,
NodeExecutors und Worker hängen an Store-Ports; Firestore und spätere SQLite-
Adapter sind austauschbare Implementierungen. Details stehen in
[`local-runtime.md`](./local-runtime.md).

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

- Aufgaben werden in Firestore unter `teams/{teamId}/tasks/{taskId}` gespeichert.
- Der Task Builder arbeitet mit Autosave: Beim Öffnen einer neuen Aufgabe und
  nach jeder Mutation ruft der Cubit `TaskRepository.saveTask()` auf.
- Es gibt keinen expliziten Speichern-Button. Nutzer:innen müssen den
  Persistenzzeitpunkt nicht selbst verwalten.
- `TaskRepository` bündelt Entwurfs-Persistenz und Ausführung. Die konkrete
  Implementierung `FirebaseTaskRepository` speichert in Firestore und ruft für
  die Ausführung die Firebase Callable Function über `TaskRunnerDatasource` auf.
- Bei der Ausführung sendet der Client nur `taskId` und optionalen Kontext.
  Die Callable Function ist authentifiziert, lädt die Aufgabe serverseitig aus
  `teams/{teamId}/tasks/{taskId}`, erstellt
  `teams/{teamId}/taskRuns/{runId}` und gibt sofort die `runId` zurück.
- Die eigentliche Ausführung läuft im Backend über einen Firestore-Trigger auf
  `taskRuns/{runId}`. Activity-Logs werden unter
  `teams/{teamId}/activities/{activityId}` gespeichert.
- Architekturentscheidung: `TaskRunDocument` bleibt die Quelle der Wahrheit für
  Status, UI, Freigaben und Wiederaufnahme. Aktuell dient Firestore zusätzlich
  als einfache Queue (`status = queued`). Für produktionsreifes Dispatching wird
  später auf Cloud Tasks gewechselt: Der Webhook oder Scheduler legt weiterhin
  zuerst den `taskRuns/{runId}`-Datensatz an und erstellt danach einen Cloud
  Task mit `{teamId, runId}`. Der Worker lädt den Run aus Firestore und führt
  ihn aus. Cloud Tasks ersetzt damit nur den Ausführungsauftrag, nicht den
  persistierten Run-Zustand.
- Freigaben laufen über `reviewTaskRunFlow`: Approve setzt einen pausierten Run
  anhand von `resumeState` fort, Reject verwirft den Zwischenzustand und setzt
  den Run auf `rejected`.
- Firestore-Dokumente enthalten `id`, `title`, `objective`, `selectedNodeId`,
  `teamId`, `graph`, `createdAt` und `updatedAt`.

### Teams und Dateien

Dateien sind von Beginn an team-scoped modelliert, auch wenn aktuell nur ein
persönlicher Arbeitsbereich verwendet wird.

Firestore:

```text
users/{uid}/notifications/{notificationId}
teams/{teamId}
teams/{teamId}/members/{uid}
teams/{teamId}/tasks/{taskId}
teams/{teamId}/taskTriggers/{triggerId}
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
teams/{teamId}/communicationChannels/{channelId}
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}
teams/{teamId}/inboxes/{channelId}/conversations/{conversationId}/messages/{messageId}
teams/{teamId}/folders/{folderId}
teams/{teamId}/files/{fileId}
teams/{teamId}/files/{fileId}/versions/{versionId}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}
teams/{teamId}/knowledgeBases/{knowledgeBaseId}/notes/{noteId}
```

Team-Einladungen werden als Notification unter
`users/{uid}/notifications/{notificationId}` geschrieben. Die Annahme der
Einladung setzt `users/{uid}.teamId` und erstellt
`teams/{teamId}/members/{uid}`.
HITL-Freigaben werden ebenfalls als Notification (`taskRunApproval`) unter den
Team-Mitgliedern verteilt und öffnen im Client den Freigabe-Dialog.

Kommunikationskanäle werden im Client unter
`Einstellungen > Kommunikation` gepflegt und bleiben bewusst team-scoped.
Provider-Credentials werden nicht im Client erfasst. Für Twilio provisioniert
novooa intern einen Subaccount pro Team und speichert dessen SID am
Team-Dokument (`twilioSubaccountSid`). Die Nutzeroberfläche spricht von
„WhatsApp/SMS/E-Mail verbinden“ und zeigt keine Provider-Begriffe wie Twilio,
Subaccount oder Account SID.

Storage:

```text
teams/{teamId}/files/{fileId}/versions/{versionId}/{fileName}
```

Der aktuelle Client erzeugt für angemeldete Nutzer:innen automatisch ein
Team-Dokument mit generierter ID und speichert die Referenz im User-Dokument:

```text
users/{uid}.teamId = "{teamId}"
teams/{teamId}
teams/{teamId}/members/{uid}
```

Die Team-ID wird nicht aus der UID abgeleitet. Client und Functions lösen den
aktuellen Team-Kontext über `users/{uid}.teamId` auf. Aufgaben,
Datei-Metadaten, Aktivitäten und Storage-Pfade bleiben team-scoped.

Copy-on-Write wird über `versions/{versionId}` vorbereitet. Eine neue
Dateiversion schreibt ein neues Storage-Objekt und aktualisiert am
Datei-Dokument `currentVersionId`.

Detailtiefe in [`features/dateien.md`](./features/dateien.md).

### Teams und Wissensbasis

Die Wissensbasis ist team-scoped, aber nicht wie Dateien versioniert. Der
aktuelle Startpunkt ist eine `default`-Knowledge-Base pro Team:

```text
teams/{teamId}/knowledgeBases/default/notes/{noteId}
```

Eine Notiz enthält Markdown-Content, Metadaten (`title`, `path`, `type`) und
`outgoingLinks` als Liste verlinkter Notiz-IDs. `type = atomic` stellt nur die
einzelne Notiz bereit. `type = moc` stellt die MOC-Notiz plus rekursiv verlinkte
Notizen bereit. Anhänge werden an unterstützten Bausteinen gespeichert; aktuell
ist nur der Prompt-Baustein angebunden.

Detailtiefe in [`features/wissensbasis.md`](./features/wissensbasis.md).

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
| Zeitgesteuert   | `taskTriggers`            | Scheduled Function → `taskRuns`            |
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
- **Modell:** Flows verwenden keine Provider direkt. Modell-Plugins und
  ModelRefs werden zentral über `functions/src/task-runner/ai-models.ts`
  bereitgestellt. Unterstützte Profile sind `google`, `minimax`,
  `openai-compatible` und `local`.
- **Export:** Jeder Flow wird in `functions/src/index.ts` re-exportiert.
- **Secrets:** Cloud-Provider-API-Keys via Secret Manager / Runtime-Env. Lokale
  Runtimes verwenden eigene lokale `.env`-Werte und dürfen keine produktiven
  Cloud-Secrets voraussetzen.
- **Streaming:** `streamSchema` setzen, wenn der Flow gestreamt werden soll.

### Vorhandene Flows

| Flow                          | Datei                            | Status                          |
| ----------------------------- | -------------------------------- | ------------------------------- |
| `runTaskDefinitionFlow`       | `functions/src/task-workflows.ts` | Produktiv (Feature Aufgabe)     |
| `reviewTaskRunFlow`           | `functions/src/task-workflows.ts` | Produktiv (Feature Aktivitäten) |
| `menuSuggestionFlow`          | `functions/src/genkit-sample.ts` | Vorlage — nicht produktiv       |

Feature-spezifische Detailtiefe (Inputs, Outputs, Executor-Registry) in
[`features/aufgabe.md`](./features/aufgabe.md#genkit-ausführung-aufgabenspezifisch).

### Neue Genkit-Tools

Eigene Tools unter `functions/src/tools/<domain>.ts` ablegen. Jeder Export
eines Tools wird über `ai.defineTool({...}, async (...) => {...})` registriert
und in dem jeweiligen Flow verwendet.
