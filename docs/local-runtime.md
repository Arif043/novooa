# Lokale Runtime

## Ziel

novooa soll später vollständig lokal laufen können: Aufgaben, Ausführungen,
Aktivitäten, Dateien, Wissensbasis und Trigger-Zustand liegen lokal. Cloud-
Provider wie Twilio bleiben optional über einen dünnen novooa-Relay nutzbar.

## Runtime-Schichten

```text
Domain
  Task-, Attachment- und Schedule-Typen
  Repository-Ports

Task Runner Core
  NodeExecutors
  TaskGraphRunner
  Template-Auflösung
  AI-Provider-Auswahl

Ports
  TaskStore
  TaskRunStore
  ActivityStore
  TeamContextStore
  TeamFileStore
  KnowledgeBaseStore
  TaskTriggerStore
  ObjectStore
  TaskRunApprovalNotificationStore
  TeamMembershipStore
  TeamMemberDirectory
  ChannelProvider

Cloud Adapter
  FirestoreTaskStore
  FirestoreTaskRunStore
  FirestoreActivityStore
  FirestoreTeamFileStore
  FirestoreKnowledgeBaseStore
  FirestoreTaskTriggerStore
  FirebaseObjectStore
  FirestoreTaskRunApprovalNotificationStore
  FirestoreTeamMembershipStore
  FirebaseTeamMemberDirectory

Local Adapter
  SQLiteTaskStore
  SQLiteTaskRunStore
  SQLiteActivityStore
  LocalTeamFileStore
  SQLiteKnowledgeBaseStore
  SQLiteTaskTriggerStore
  LocalObjectStore
```

## Lokale Datenhaltung

SQLite ist der Default für strukturierte lokale Daten. Es braucht keinen Server,
ist transaktional und eignet sich für Aufgaben, Runs, Aktivitäten, Trigger,
Teams, Kanäle und Wissensbasis-Metadaten.

Die erste Migration liegt in
[`local-runtime/migrations/001_initial.sql`](../local-runtime/migrations/001_initial.sql).
Sie legt diese Tabellen an:

```text
teams
team_members
tasks
task_runs
activities
task_triggers
communication_channels
knowledge_notes
files
file_versions
```

Dateien liegen im lokalen Dateisystem:

```text
.novooa/
  files/{teamId}/{fileId}/versions/{versionId}/{fileName}
  knowledge/{teamId}/...
```

## Lokale Identität und Teams

Firebase Auth ist für eine rein lokale Runtime nicht erforderlich. Beim ersten
Start wird ein lokaler Nutzer und ein lokales Team erzeugt. Das Team-Feature
bleibt erhalten, wird lokal aber über `teams` und `team_members` abgebildet.
Ein späterer Cloud-Login kann zusätzlich für Sync, Migration oder Relay-Zugriff
verwendet werden.

## Twilio und externe Trigger

Twilio wird nicht direkt auf jede lokale Installation zeigen. Stattdessen nutzt
die lokale Runtime einen novooa Cloud Relay:

```text
Twilio
→ novooa Cloud Relay
→ lokale novooa Runtime
→ SQLite task_runs
→ lokaler Worker
```

Ausgehende Nachrichten laufen umgekehrt:

```text
lokale novooa Runtime
→ novooa Cloud Relay
→ Twilio
```

Der Relay verwaltet Twilio-Credentials und Subaccounts zentral. Die lokale
Runtime authentifiziert sich beim Relay über ein Geräte-/Workspace-Token. Wenn
die lokale Runtime offline ist, kann der Relay Events puffern und später
zustellen.

## Aktueller Implementierungsstand

- `functions/src/domain/entities/` enthält reine Domain-Typen ohne Firebase
  oder Genkit.
- `functions/src/task-runner/ai-models.ts` kapselt AI Provider.
- `functions/src/domain/repositories/task-store.ts` definiert `TaskStore`.
- `functions/src/domain/repositories/task-run-store.ts` definiert `TaskRunStore`.
- `functions/src/domain/repositories/activity-store.ts` definiert `ActivityStore`.
- `functions/src/domain/repositories/team-file-store.ts` definiert `TeamFileStore`.
- `functions/src/domain/repositories/knowledge-base-store.ts` definiert `KnowledgeBaseStore`.
- `functions/src/domain/repositories/task-trigger-store.ts` definiert `TaskTriggerStore`.
- `functions/src/domain/repositories/team-context-store.ts` definiert `TeamContextStore`.
- `functions/src/domain/repositories/object-store.ts` definiert `ObjectStore`.
- `functions/src/domain/repositories/task-run-approval-notification-store.ts`
  definiert den Port für HITL-Benachrichtigungen.
- `functions/src/domain/repositories/team-membership-store.ts` und
  `team-member-directory.ts` definieren Ports für Teamverwaltung.
- Team-Mitgliedschaftsaktionen liegen als Use-Cases unter
  `functions/src/domain/usecases/`.
- `functions/src/task-runner/task-run-worker.ts` führt Runs über Store-Ports aus.
- Scheduler und Channel-Dispatcher arbeiten über `TaskTriggerStore`.
- Node- und Skill-Attachments werden über `ObjectStore` geladen.
- Wissensbasis-Attachments werden über `KnowledgeBaseStore` aufgelöst und in
  den lokalen Node-Workspace geschrieben.
- HITL-Benachrichtigungen werden in Firebase über
  `FirestoreTaskRunApprovalNotificationStore` geschrieben.
- Firestore-Adapter unter `functions/src/infrastructure/firebase/`
  implementieren aktuell die Cloud-Version.
- Lokale SQL-Adapter sind für `TaskStore`, `TaskRunStore`, `ActivityStore`,
  `TaskTriggerStore` und `KnowledgeBaseStore` vorbereitet. Sie hängen nur an
  `LocalSqlDatabase`, noch nicht an einer konkreten SQLite-Library.
- `LocalTeamFileStore` schreibt Dateien in ein lokales Root-Verzeichnis und
  persistiert Datei-/Versions-Metadaten über `LocalSqlDatabase`.
- `SqlMigrationRunner` wendet Migrationen treiberneutral über
  `LocalSqlDatabase` an.

## Nächste Schritte

1. Konkreten SQLite-Treiber für `LocalSqlDatabase` anbinden.
2. Lokalen Worker-Prozess mit `TaskRunWorkerStores` starten.
3. Lokalen HTTP-Endpunkt für Relay-Events implementieren.
4. Cloud Relay für Twilio Webhooks und ausgehende Nachrichten trennen.
