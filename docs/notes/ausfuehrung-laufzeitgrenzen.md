# Laufzeitgrenzen der Ausführung

> `TaskWorkflow` und `NodeExecutor` sind frameworkfreie Domain-Verträge; Genkit, SQLite und Workspaces hängen nur in der Infrastructure.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **`TaskWorkflow`:** Vertrag für Start, Review und Queue-Ausführung.
  `createGenkitTaskWorkflow` implementiert ihn mit dem Genkit-Runner.
- **Runtime-Host** `local-runtime-task-workflow.ts`: verdrahtet SQLite,
  Dateien, Benachrichtigungen, Script-Dienst und Modellinferenz.
- **Assistent** nach demselben Muster: `TaskBuilderAssistant` (Vertrag),
  `createGenkitTaskBuilderAssistant`; in Firebase läuft er nur im
  [Relay](./aufgabenstudio-agent-relay.md).
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
