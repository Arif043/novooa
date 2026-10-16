# Laufzeitgrenzen der Ausführung

> `TaskWorkflow` und `NodeExecutor` sind frameworkfreie Domain-Verträge; Genkit, Firebase und Workspaces hängen nur in der Infrastructure.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **`TaskWorkflow`:** Vertrag für Start, Review und Queue-Ausführung.
  `createGenkitTaskWorkflow` implementiert ihn mit dem Genkit-Runner.
- **Firebase-Host** `task-workflow-functions.ts`: validiert Callable-Payloads,
  überträgt Firebase-Auth in den Workflow-Kontext, adaptiert Cloud-Tasks.
  `CloudTaskRuntimeFactory` verdrahtet Firestore, Storage,
  Benachrichtigungen und Modellinferenz.
- **Assistent** nach demselben Muster: `TaskBuilderAssistant` (Vertrag),
  `createGenkitTaskBuilderAssistant`, `task-builder-assistant-functions.ts`
  (Auth, Payload-Prüfung, Secret).
- **`NodeExecutor`**, seine Eingabe und der Laufzeitkontext liegen in der
  Domain und kennen weder Genkit noch einen Anhangs-Workspace. Die Registry
  bindet Genkit nur für `prompt` und `iterativeRefinement`; auch `script`
  bekommt seinen Workspace erst dort.
- **Domain-Executoren:** `modelInference` (`ModelInference`), Dateien
  (`TeamFileStore`), Senden (`TaskMessageSender`), `readFile`, `forEach`,
  Eingaben, Ereignislesen und Pausen. Deterministische Bausteine (Eingabe,
  Bedingung, Freigabe) brauchen keinen externen Port.
- Failure-Codes (`invalidRequest`, `invalidTaskId`, `invalidReviewDecision`,
  `invalidFormValues`) liegen in der Domain; HTTP- und Datasource-Exceptions
  übersetzt der Client in fachliche Failures.

## Siehe auch

- [Run starten](./run-start.md)
- [Anhänge und Workspace](./anhaenge-workspace.md)
