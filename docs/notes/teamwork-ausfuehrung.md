# Ausführung der Teamarbeit

> Der Orchestrator ruft jeden Mitarbeiter über ein eigenes Delegations-Werkzeug auf; jeder Mitarbeiter führt ein Gespräch über den Lauf auf der Genkit-Instanz seines Modells, alle teilen einen Arbeitsordner, und ein eigenes Modell prüft das Ergebnis.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md) · [Aufgabe](../index/aufgabe.md)

- **Code:** `functions/src/features/task_execution/infrastructure/genkit/executors/teamwork/`, Port `TeamworkExecutor` (Domain).
- **Arbeitsordner** (`runner/teamwork-workspace.ts`, `novooa-teamwork-*`):
  - Anhänge und `knowledge/` liegen in der Wurzel, wie beim Prompt-Baustein.
  - `shared/` ist die gemeinsame Ablage für Zwischenergebnisse und Ergebnisdateien.
  - `images/bild-<n>.<ext>` enthält die Bilder der Anweisung (`teamwork-images.ts`). Der Orchestrator bekommt sie mit der Anweisung und dazu den Hinweis, Mitarbeitern den Pfad zu nennen. Mitarbeiter sehen Bilder nur so: `read_file` gibt Bilddateien als Bild an ihr Modell.
  - `employees/<id>/skills/` enthält die Fähigkeiten je Mitarbeiter; nur dieser Mitarbeiter bekommt den Pfad in `skills({skillPaths})`.
  - Alle Agenten haben `filesystem({rootDirectory, allowWriteAccess: true})`. Pfade außerhalb der Wurzel lehnt die Middleware ab, und der Ordner wird nach dem Lauf gelöscht.
- **Modelle** (`teamworkModelFor`):
  - dieselbe Rückfallkette wie beim [Prompt-Executor](./prompt-executor.md);
  - jeder Agent braucht `toolCalling`, Orchestrator und Prüfung zusätzlich `structuredOutput`; sonst gibt es `ModelCapabilityMissingError` mit der Rolle, bevor etwas läuft.
- **Delegation** (`delegationToolsFor`):
  - je Mitarbeiter ein `ai.dynamicTool` `delegate_to_<name>` (ASCII, eindeutig) mit der Eingabe `{task, expectedResult, boundaries?}`; der Mitarbeiter bekommt sie gegliedert als „Auftrag / Erwartetes Ergebnis / Grenzen“;
  - höchstens 10 Aufträge je Lauf (`DelegationBudget`), auch über Nachbesserungen hinweg;
  - ein Fehler geht als Antwort zurück, und der Orchestrator arbeitet weiter.
- **Gedächtnis** (`runner/employee-conversation.ts`):
  - Jeder Mitarbeiter hat je Lauf ein `EmployeeConversation`: ein Genkit-Agent (`defineAgent`) in einer Kind-Registry seiner eigenen Genkit-Instanz, mit der Rahmenbedingung als System-Prompt. Folgeaufträge gehen per `chat.send()` in dasselbe Gespräch.
  - Ohne Ausgabeschema: Mit Schema scheitert der Agent beim Kopieren seines Zustands („could not be cloned“, siehe [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)). Mitarbeiter liefern ohnehin Freitext.
  - Aufträge an denselben Mitarbeiter laufen nacheinander, weil ein Chat keinen zweiten Turn gleichzeitig annimmt.
- **Warum nicht Genkits `agents`-Middleware:** Sie findet Agenten nur in der Registry des Orchestrators. Ein Modell eines anderen Anbieters (andere Genkit-Instanz) ist dort nicht auffindbar.
- **Orchestrator:**
  - `ai.generate` mit System-Prompt (`teamwork-prompts.ts`: Team, Arbeitsordner, Datei-Felder), Delegations-Werkzeugen, Arbeitsordner und `output: {schema}` (`teamworkSchemaFor`);
  - höchstens 12 Schritte je Runde;
  - der System-Prompt regelt auch Aufwand (einfache Aufgaben mit ein bis zwei Aufträgen, nichts doppelt) und Ende (abschließen, sobald die Anweisung erfüllt ist).
- **Prüfung** (`teamwork-review.ts`, `teamwork-review-loop.ts`):
  - eigenes Modell aus `review.languageModelId`, ein `generate` mit Ausgabe `{approved, findings}` und nur lesendem Zugriff auf den Arbeitsordner (`allowWriteAccess: false`);
  - Beanstandung: Der Orchestrator setzt sein bisheriges Gespräch fort (`messages` der letzten Antwort plus Befund) und kann Folgeaufträge vergeben;
  - höchstens 2 Nachbesserungen; danach wird das letzte Ergebnis geliefert.
- **Ergebnis:**
  - Wertfelder werden mit `fieldOutputsFor` typisiert; `json` kommt als Text und wird geparst.
  - Datei-Felder liefern einen Pfad unter `shared/`. `persistedResultFile` prüft ihn (Datei existiert, höchstens 5 MB) und legt sie mit `TeamFileStore.writeTeamFile` als Team-Datei ab. Pfade außerhalb von `shared/` gelten als `ModelOutputSchemaError`.
  - Datei-Felder sind Schreibstellen für den Schleifenschutz der Zeitpläne (`fileWriteSitesOf`).
- **Protokoll:**
  - Der Orchestrator steht als „Modelcall“ `Teamwork / Orchestrator` im Protokoll.
  - Die Prüfung steht als „Modelcall“ `Teamwork / Prüfung <n>`, ihr Urteil als `[Teamwork] Review <n> passed` oder `[Teamwork] Review <n> rejected` mit Befund.
  - Jeder Auftrag erscheint als `[Teamwork] Task for <Mitarbeiter>` und jede Antwort als `[Teamwork] Answer from <Mitarbeiter> (<Dauer>)`, jeweils gekürzt auf 2000 Zeichen.

## Siehe auch

- [Baustein „Teamarbeit“](./teamwork-baustein.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
- [Anhänge und Workspace](./anhaenge-workspace.md)
