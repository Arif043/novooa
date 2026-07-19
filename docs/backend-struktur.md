# Backend-Struktur

## Ist-Zustand

Das Backend liegt aktuell in einem einzigen TypeScript-Paket unter
`functions/src`.

```text
functions/src/
  index.ts                 Firebase Export-Root
  task-workflows.ts        Callable Flows und Firestore Worker
  schedule-workflows.ts    Cloud Scheduler Entry Point
  team-workflows.ts        Team-Callables
  task-runner/             Task-Runner-Core und Cloud-Adapter
  task-executors/          Baustein-Executoren
  channels/                Kommunikation, Trigger-Dispatch, Sender
  twilio/                  Twilio Webhook und Mapping
  schedule/                Zeitplan-Runner und Zeitberechnung
  triggers/                Trigger-Ports und Firestore-Adapter
  local-runtime/           lokale SQL-/Dateisystem-Adapter
```

## Zielstruktur

Der Task Runner soll unabhängig von Firebase ausführbar sein. Cloud Functions
und lokale Runtime sollen nur unterschiedliche Adapter bereitstellen.

```text
Core
  task-runner/
  task-executors/
  schedule/schedule-next-run.ts

Ports
  TaskStore
  TaskRunStore
  ActivityStore
  TaskTriggerStore
  KnowledgeBaseStore
  TeamFileStore
  TeamContextStore

Cloud Adapter
  FirestoreTaskStore
  FirestoreTaskRunStore
  FirestoreActivityStore
  FirestoreTaskTriggerStore
  FirestoreKnowledgeBaseStore
  FirestoreTeamFileStore

Local Adapter
  SQLiteTaskStore
  SQLiteTaskRunStore
  SQLiteActivityStore
  SQLiteTaskTriggerStore
  SQLiteKnowledgeBaseStore
  LocalTeamFileStore
```

## Leitplanken

- Entry Points importieren Cloud-SDKs.
- Store-Adapter importieren Persistenz-SDKs.
- Runner, Executor-Registry und Graph-Logik importieren keine Firebase-SDKs.
- Lokale Adapter hängen an `LocalSqlDatabase`, nicht an einer konkreten
  SQLite-Library.
- Migrationen werden über `SqlMigrationRunner` angewendet, nicht aus
  Cloud Functions heraus gestartet.

## Offene Entkopplungen

- `node-attachment-workspace.ts` lädt Dateien noch direkt aus Firebase Storage.
- `skill-workspace.ts` lädt Skills noch direkt aus Firebase Storage.
- `task-run-approval-notifier.ts` schreibt Notifications noch direkt nach
  Firestore.
- Channel-Sender und Team-Workflows sind noch Cloud-spezifisch.
