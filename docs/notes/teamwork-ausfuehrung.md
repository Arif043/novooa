# Ausführung der Teamarbeit

> Der Orchestrator ruft jeden Mitarbeiter über ein eigenes Delegations-Werkzeug auf; jeder Agent läuft auf der Genkit-Instanz seines Modells, alle teilen einen Arbeitsordner.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md) · [Aufgabe](../index/aufgabe.md)

- **Code:** `functions/src/features/task_execution/infrastructure/genkit/executors/teamwork/`, Port `TeamworkExecutor` (Domain).
- **Arbeitsordner** (`runner/teamwork-workspace.ts`, `novooa-teamwork-*`):
  - Anhänge und `knowledge/` liegen in der Wurzel, wie beim Prompt-Baustein.
  - `shared/` ist die gemeinsame Ablage für Zwischenergebnisse und Ergebnisdateien.
  - `employees/<id>/skills/` enthält die Fähigkeiten je Mitarbeiter; nur dieser Mitarbeiter bekommt den Pfad in `skills({skillPaths})`.
  - Alle Agenten haben `filesystem({rootDirectory, allowWriteAccess: true})`. Pfade außerhalb der Wurzel lehnt die Middleware ab, und der Ordner wird nach dem Lauf gelöscht.
- **Modelle** (`teamworkModelFor`):
  - dieselbe Rückfallkette wie beim [Prompt-Executor](./prompt-executor.md);
  - jeder Agent braucht `toolCalling`, der Orchestrator zusätzlich `structuredOutput`; sonst gibt es `ModelCapabilityMissingError` mit der Rolle.
- **Delegation** (`delegationToolsFor`):
  - je Mitarbeiter ein `ai.dynamicTool` `delegate_to_<name>` (ASCII, eindeutig) mit der Eingabe `{task}`;
  - der Mitarbeiter läuft mit `runEmployeeAgentTurn` (Rahmenbedingung als System-Prompt) auf seiner eigenen Genkit-Instanz;
  - höchstens 10 Aufträge je Lauf (`DelegationBudget`);
  - ein Fehler geht als Antwort zurück, und der Orchestrator arbeitet weiter.
- **Warum nicht Genkits `agents`-Middleware:** Sie findet Agenten nur in der Registry des Orchestrators. Ein Modell eines anderen Anbieters (andere Genkit-Instanz) ist dort nicht auffindbar.
- **Orchestrator:**
  - `ai.generate` mit System-Prompt (`teamwork-prompts.ts`: Team, Arbeitsordner, Datei-Felder), Delegations-Werkzeugen, Arbeitsordner und `output: {schema}` (`teamworkSchemaFor`);
  - höchstens 12 Runden.
- **Ergebnis:**
  - Wertfelder werden mit `fieldOutputsFor` typisiert; `json` kommt als Text und wird geparst.
  - Datei-Felder liefern einen Pfad unter `shared/`. `persistedResultFile` prüft ihn (Datei existiert, höchstens 5 MB) und legt sie mit `TeamFileStore.writeTeamFile` als Team-Datei ab. Pfade außerhalb von `shared/` gelten als `ModelOutputSchemaError`.
  - Datei-Felder sind Schreibstellen für den Schleifenschutz der Zeitpläne (`fileWriteSitesOf`).
- **Protokoll:**
  - Der Orchestrator steht als „Modelcall“ `Teamwork / Orchestrator` im Protokoll.
  - Jeder Auftrag erscheint als `[Teamwork] Task for <Mitarbeiter>` und jede Antwort als `[Teamwork] Answer from <Mitarbeiter> (<Dauer>)`, jeweils gekürzt auf 2000 Zeichen.

## Siehe auch

- [Baustein „Teamarbeit“](./teamwork-baustein.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
- [Anhänge und Workspace](./anhaenge-workspace.md)
