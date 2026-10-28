# Ausführung eines Mitarbeiters

> Ein Mitarbeiter läuft als einzelner Modellaufruf ohne gespeicherten Verlauf; im Prompt-Baustein ist seine Rahmenbedingung ein eigener Systemabschnitt neben der Grundrolle.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md)

1. [`prepareNodeAttachmentWorkspace`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-workspace.ts)
   lädt den Mitarbeiter über den `EmployeeStore` (Teil der
   `TaskGraphRuntime`) und legt `workspace.employee = {id, name, constraint}`
   ab. **Seine Fähigkeiten ersetzen die des Bausteins** und werden nach
   `<workspace>/skills/<name>/` kopiert. Auch ohne Fähigkeiten entsteht ein
   Workspace, damit die Rahmenbedingung ankommt.
2. **Prompt-Baustein:** Der Aufruf läuft über das
   [LLM-Framework](./llm-aufruf-framework.md). Die Rahmenbedingung steht als
   `<employee name="…">` im Systemteil, die Rolle verweist darauf; sie ersetzt
   die Grundanweisungen nicht mehr. Leere Rahmenbedingung → kein Abschnitt.
   **Iterative Verfeinerung** nutzt noch
   [`employee-agent.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/employee-agent.ts):
   dort ist die Rahmenbedingung der ganze System-Prompt (Umstellung geplant).
   `use` reicht Retry-, Dateisystem- und Skill-Middleware durch.
3. **Kein `defineAgent`:** Genkits Agent (Beta, 1.42) legt die Modellantwort
   samt Parser-Funktion in seinen Session-Zustand und kopiert ihn mit
   `structuredClone`. Mit Ausgabeschema (strukturierte Ausgabe, Entscheidung)
   scheitert das immer mit „… could not be cloned“. Für einen Turn ohne
   Verlauf bringt der Agent nichts darüber hinaus; ein Test belegt die
   strukturierte Ausgabe.

In der [Teamarbeit](./teamwork-ausfuehrung.md) führt jeder Mitarbeiter dagegen
ein Gespräch über den ganzen Lauf (`EmployeeConversation`, `defineAgent` ohne
Ausgabeschema).

Bilder im Prompt gehen als Medienteile mit; die Rahmenbedingung bleibt auch
dann im Systemteil.

## Siehe auch

- [Fähigkeiten an Bausteinen](./skills-an-bausteinen.md)
- [Prompt-Executor](./prompt-executor.md)
