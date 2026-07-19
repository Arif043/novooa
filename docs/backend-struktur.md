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
  domain/entities/         reine Task-, Attachment- und Schedule-Typen
  domain/repositories/     Ports für Runner, Storage und Adapter
  infrastructure/firebase/ Firestore-/Storage-/Firebase-Adapter
  infrastructure/local/    SQLite-/Dateisystem-Adapter
  task-runner/             Task-Runner-Core und Facades
  task-executors/          Baustein-Executoren
  channels/                Kommunikation, Trigger-Dispatch, Sender
  twilio/                  Twilio Webhook und Mapping
  schedule/                Zeitplan-Runner und Zeitberechnung
```

## Zielstruktur

Der Task Runner soll unabhängig von Firebase ausführbar sein. Cloud Functions
und lokale Runtime sollen nur unterschiedliche Adapter bereitstellen.

```text
Core
  task-runner/
  task-executors/
  schedule/schedule-next-run.ts

Domain
  domain/entities/
  domain/repositories/

Cloud Adapter
  infrastructure/firebase/

Local Adapter
  infrastructure/local/
```

## Leitplanken

- Entry Points importieren Cloud-SDKs.
- Store-Adapter importieren Persistenz-SDKs.
- `domain/` importiert keine Firebase-, Genkit- oder Runner-Module.
- Runner, Executor-Registry und Graph-Logik importieren keine Firebase-SDKs.
- Datei-Downloads laufen über `ObjectStore`, nicht direkt über Firebase Storage.
- Freigabe-Notifications laufen über `TaskRunApprovalNotificationStore`.
- `task-runner/task-definition.ts` bleibt vorerst die Schema- und
  Validierungsschicht für Genkit/Zod und re-exportiert Domain-Typen.
- Lokale Adapter hängen an `LocalSqlDatabase`, nicht an einer konkreten
  SQLite-Library.
- Migrationen werden über `SqlMigrationRunner` angewendet, nicht aus
  Cloud Functions heraus gestartet.

## Offene Entkopplungen

- Channel-Sender und Team-Workflows sind noch Cloud-spezifisch.
- `task-runner/task-definition.ts` enthält weiterhin Genkit/Zod-Schemas und ist
  damit bewusst noch Adapter-nah.
