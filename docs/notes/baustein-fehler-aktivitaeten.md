# Fehlgeschlagene Bausteine in den Aktivitäten

> Scheitert ein Baustein, scheitert der Lauf; die Aktivitäten zeigen trotzdem alle Bausteine in Planreihenfolge, inklusive des gescheiterten mit Fehler und Ausgabe.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Der Port `NodeExecutor.execute` liefert
  `Result<NodeExecutionResult, NodeFailure>`. `NodeFailure`
  (`domain/entities/node-failure.ts`) ist ein Value Object: stabiler Code,
  sprachneutraler technischer Text, Felder für die Übersetzung. Die Domain
  wirft keine eigenen Exceptions für Geschäftsfehler.
- Der Runner (`task-graph-runner.ts`) macht an der Infrastrukturgrenze daraus
  eine `NodeExecutionFailure` (`domain/entities/node-execution-failure.ts`:
  gescheiterter Baustein, abgeschlossene Ergebnisse, `cause`): aus einer
  `NodeFailure` mit Code und Feldern, aus einer geworfenen Exception nur mit
  Text.
- Verschachtelte Pläne (Zweige, Schleifen) laufen über den Port `runGraph`,
  der `Result<NodeExecutionResult[], NodeFailure>` liefert. Die Failure des
  inneren Bausteins geht unverändert an den äußeren; eine innere Exception
  wird zu `unexpected` mit ihrem Text.
- Der Port `ScriptExecutor` liefert einen Fehler im Script als Failure
  `scriptFailed` samt Konsole; sie füllt `FailedNode.console`.
- Alle Codes und Felder: [Fehlercodes der Bausteine](./baustein-fehlercodes.md).
- `executeTaskGraph`/`resumeTaskGraph` geben
  `ResultAsync<TaskGraphOutput, NodeExecutionFailure>` zurück und werden mit
  `map`/`match` weiterverarbeitet.
- `markRunFailed` schreibt die Bausteine über `recordNodeExecutionFailure`,
  bevor es den Lauf als gescheitert festhält.
- `TaskRunFailure` bleibt Eingabefehlern der HTTP-Routen vorbehalten.
- Der Code einer `NodeFailure` wird `FailedNode.failureCode`; gespeichert in
  `activities.failure_code`. Ihre Felder (`details`) landen in
  `FailedNode.failureDetails`, gespeichert in
  `activities.failure_details_json`. Der Client
  übersetzt bekannte Codes mit diesen Feldern und zeigt den Text der Runtime
  als technische Details
  ([Fehlerschichtung](./fehlerschichtung-modellaufruf.md)).
- Streng steigende Zeitstempel (ms) im SQLite-Aktivitäts-Store sichern die
  Reihenfolge.
- Die Lauf-Meldung erscheint nur dann als eigener Eintrag oben, wenn kein
  Baustein die Ursache war (etwa ein ungültiger Plan).
- Nach einer Freigabe werden nur neu hinzugekommene Ergebnisse geschrieben.

## Siehe auch

- [Task-Run-Warteschlange](./task-run-warteschlange.md)
- [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)
- [Run starten](./run-start.md)
- [Fehlerschichtung eines Modellaufrufs](./fehlerschichtung-modellaufruf.md)
- [Fehlercodes der Bausteine](./baustein-fehlercodes.md)
