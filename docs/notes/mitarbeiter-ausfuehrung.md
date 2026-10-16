# Ausführung eines Mitarbeiters

> Ein Mitarbeiter läuft als Genkit-Agent (`ai.defineAgent`, Beta) in einer Kind-Registry, ein frischer Chat je Turn, mit der Rahmenbedingung als System-Prompt.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md)

1. [`prepareNodeAttachmentWorkspace`](../../functions/src/features/task_execution/infrastructure/genkit/runner/node-attachment-workspace.ts)
   lädt den Mitarbeiter über den `EmployeeStore` (Teil der
   `TaskGraphRuntime`) und legt `workspace.employee = {id, name, constraint}`
   ab. **Seine Fähigkeiten ersetzen die des Bausteins** und werden nach
   `<workspace>/skills/<name>/` kopiert. Auch ohne Fähigkeiten entsteht ein
   Workspace, damit die Rahmenbedingung ankommt.
2. [`employee-agent.ts`](../../functions/src/features/task_execution/infrastructure/genkit/runner/employee-agent.ts)
   definiert `defineAgent({name, system: constraint, model, use, output,
   config})` und führt einen Turn mit `chat().send(anweisung)` aus. `use`
   reicht Retry-, Dateisystem- und Skill-Middleware durch. Leere
   Rahmenbedingung → kein System-Prompt.
3. **Kind-Registry:** `defineAgent` registriert fünf Actions je Agent; auf der
   langlebigen Registry würden sie nie verschwinden (gemessen 2 → 17 nach drei
   Agenten). Deshalb `Registry.withParent(ai.registry)`, mit dem Turn geräumt;
   ein Test belegt gleichbleibende Größe nach fünf Turns. Der Name bleibt per
   UUID eindeutig.
4. Kein Session-Store: kein gespeicherter Verlauf.

Bausteine mit Bildern im Prompt gehen unverändert über den `generate`-Pfad,
ohne Agent.

## Siehe auch

- [Fähigkeiten an Bausteinen](./skills-an-bausteinen.md)
- [Prompt-Executor](./prompt-executor.md)
