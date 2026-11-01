# Ausführung der Teamarbeit

> Der Orchestrator ruft jeden Mitarbeiter über ein eigenes Delegations-Werkzeug auf; jeder Mitarbeiter führt ein Gespräch über den Lauf auf der Genkit-Instanz seines Modells, alle teilen einen Arbeitsordner, und ein eigenes Modell prüft das Ergebnis.

Gehört zu: [Mitarbeiter](../index/mitarbeiter.md) · [Aufgabe](../index/aufgabe.md)

- **Code:** `functions/src/features/task_execution/infrastructure/genkit/executors/teamwork/`, Port `TeamworkExecutor` (Domain).
- **Arbeitsordner** (`runner/teamwork-workspace.ts`, `novooa-teamwork-*`):
  - Anhänge und `knowledge/` liegen in der Wurzel, wie beim Prompt-Baustein.
  - `shared/` ist die gemeinsame Ablage für Zwischenergebnisse und Ergebnisdateien.
  - `images/bild-<n>.<ext>` enthält die Bilder der Anweisung (`teamwork-images.ts`, geschrieben vom Executor). Der Orchestrator bekommt sie als Medienteile und im Abschnitt `<attachments>` den Hinweis, Mitarbeitern den Pfad zu nennen. Mitarbeiter sehen Bilder nur so: `read_file` gibt Bilddateien als Bild an ihr Modell.
  - `employees/<id>/skills/` enthält die Fähigkeiten je Mitarbeiter; nur dieser Mitarbeiter bekommt den Pfad in `skills({skillPaths})`.
  - Alle Agenten haben `filesystem({rootDirectory, allowWriteAccess: true})`. Pfade außerhalb der Wurzel lehnt die Middleware ab, und der Ordner wird nach dem Lauf gelöscht.
- **Modelle** (`teamworkModelFor`):
  - dieselbe Rückfallkette wie beim [Prompt-Executor](./prompt-executor.md);
  - Fähigkeiten werden nicht vorab geprüft ([Fähigkeiten zur Laufzeit](./sprachmodell-faehigkeiten-zur-laufzeit.md)); lehnt ein Anbieter ab oder beauftragt der Orchestrator trotz Mitarbeitern niemanden, endet der Baustein mit `capabilityMissing`.
- **Delegation** (`delegationToolsFor`):
  - je Mitarbeiter ein `ai.dynamicTool` `delegate_to_<name>` (ASCII, eindeutig) mit der Eingabe `{task, expectedResult, boundaries?}`; der Mitarbeiter bekommt sie als `<task>` mit `<context name="expected_result">` und `<context name="boundaries">`;
  - höchstens 10 Aufträge je Lauf (`DelegationBudget`), auch über Nachbesserungen hinweg;
  - ein Fehler geht als Antwort zurück, und der Orchestrator arbeitet weiter.
- **Gedächtnis** (`runner/employee-conversation.ts`):
  - Jeder Mitarbeiter hat je Lauf ein `EmployeeConversation`: ein Genkit-Agent (`defineAgent`) in einer Kind-Registry seiner eigenen Genkit-Instanz. Sein Systemteil (`memberSystemPrompt`: Rolle, `<employee>` mit der Rahmenbedingung, Arbeitsordner, Antwortsprache) wird mit dem [LLM-Framework](./llm-aufruf-framework.md) gebaut. Folgeaufträge gehen per `chat.send()` in dasselbe Gespräch.
  - Ohne Ausgabeschema: Mit Schema scheitert der Agent beim Kopieren seines Zustands („could not be cloned“, siehe [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)). Mitarbeiter liefern ohnehin Freitext.
  - Aufträge an denselben Mitarbeiter laufen nacheinander, weil ein Chat keinen zweiten Turn gleichzeitig annimmt.
- **Warum nicht Genkits `agents`-Middleware:** Sie findet Agenten nur in der Registry des Orchestrators. Ein Modell eines anderen Anbieters (andere Genkit-Instanz) ist dort nicht auffindbar.
- **Orchestrator:**
  - Aufruf über das [LLM-Framework](./llm-aufruf-framework.md) (`orchestratorPrompt`): Regeln, `<attachments>` (Anhänge, Bilder), `<reference name="team">`, `<reference name="workspace">`, Formathinweis für Datei-Felder und die Anweisung wörtlich als `<task>`; dazu Delegations-Werkzeuge, Arbeitsordner und strukturierte Ausgabe (`teamworkResultFields`, Datei-Felder als Pfad);
  - höchstens 12 Schritte je Runde;
  - die Regeln bestimmen auch Aufwand (einfache Aufgaben mit ein bis zwei Aufträgen, nichts doppelt), Ende (abschließen, sobald die Anweisung erfüllt ist) und dass Aufträge in der Sprache der Aufgabe geschrieben werden.
- **Prüfung** (`teamwork-review.ts`, `teamwork-review-loop.ts`):
  - eigenes Modell aus `review.languageModelId`, ein Aufruf über das LLM-Framework (`reviewPrompt`: Anweisung als `<task>`, Felder und Ergebnis als `<context>`) mit Ausgabe `{approved, findings}` (Befunde dürfen leer sein) und nur lesendem Zugriff auf den Arbeitsordner (`allowWriteAccess: false`);
  - Beanstandung: Der Orchestrator setzt sein bisheriges Gespräch fort (`LlmResponse.conversation` als `continuation`, dazu `revisionPrompt` mit dem Befund als `<context name="findings">`) und kann Folgeaufträge vergeben;
  - höchstens 2 Nachbesserungen; danach wird das letzte Ergebnis geliefert.
- **Ergebnis:**
  - Wertfelder werden mit `fieldOutputsFor` typisiert; `json` kommt als Text und wird geparst.
  - Datei-Felder liefern einen Pfad unter `shared/`. `persistedResultFile` prüft ihn (Datei existiert, höchstens 5 MB) und legt sie mit `TeamFileStore.writeTeamFile` als Team-Datei ab. Pfade außerhalb von `shared/` gelten als `ModelOutputSchemaError`.
  - Datei-Felder sind Schreibstellen für den Schleifenschutz der Zeitpläne (`fileWriteSitesOf`).
- **Protokoll:**
  - Jede Runde des Orchestrators steht mit dem gerenderten Prompt als „Modelcall“ `Teamwork / Orchestrator` bzw. `Teamwork / Orchestrator (Überarbeitung <n>)` im Protokoll.
  - Die Prüfung steht als „Modelcall“ `Teamwork / Prüfung <n>`, ihr Urteil als `[Teamwork] Review <n> passed` oder `[Teamwork] Review <n> rejected` mit Befund.
  - Jeder Auftrag erscheint als `[Teamwork] Task for <Mitarbeiter>` und jede Antwort als `[Teamwork] Answer from <Mitarbeiter> (<Dauer>)`, jeweils gekürzt auf 2000 Zeichen.
- **Gespräch** (`teamwork-transcript.ts`):
  - `TeamworkTranscript` schreibt jede Protokollzeile und sammelt dazu einen ungekürzten Eintrag (`TeamworkConversationEntry`, Domain): `task` mit erwartetem Ergebnis und Grenzen, `answer` mit Dauer, `failure` (diese drei mit `memberId` und `memberName`; die ID bestimmt die Farbe des Mitarbeiters in der App), `reviewPassed`/`reviewRejected` mit Runde und Befund, `result` mit dem Ergebnis als JSON.
  - Der Baustein legt das Transkript an und hängt das Gespräch an sein Ergebnis (`NodeExecutionResult.conversation`) oder, wenn er scheitert, an die Failure (`NodeFailure.withConversation` → `FailedNode.conversation`).
  - Gespeichert wird es an der Aktivität in `activities.conversation_json` (Migration 0024, geliefert als `conversation` in `GET /v1/activities`). Angezeigt wird es über die [Aktivitäten-Seite](./aktivitaeten-seite.md).

## Siehe auch

- [Baustein „Teamarbeit“](./teamwork-baustein.md)
- [Ausführung eines Mitarbeiters](./mitarbeiter-ausfuehrung.md)
- [Anhänge und Workspace](./anhaenge-workspace.md)
