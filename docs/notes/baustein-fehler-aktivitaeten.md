# Fehlgeschlagene Bausteine in den Aktivitäten

> Scheitert ein Baustein, scheitert der Lauf; die Aktivitäten zeigen trotzdem alle Bausteine in Planreihenfolge, inklusive des gescheiterten mit Fehler und Ausgabe.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Der Runner fängt die Exception an der Infrastrukturgrenze und liefert eine
  `NodeExecutionFailure` (`domain/entities/node-execution-failure.ts`:
  gescheiterter Baustein, abgeschlossene Ergebnisse, `cause`) als `Result`
  von `neverthrow`.
- `executeTaskGraph`/`resumeTaskGraph` geben
  `ResultAsync<TaskGraphOutput, NodeExecutionFailure>` zurück und werden mit
  `map`/`match` weiterverarbeitet.
- `markRunFailed` schreibt die Bausteine über `recordNodeExecutionFailure`,
  bevor es den Lauf als gescheitert festhält.
- `TaskRunFailure` bleibt Eingabefehlern der HTTP-Routen vorbehalten.
- Wirft ein Executor `NodeFailedError`, übernimmt der Runner dessen Code als
  `FailedNode.failureCode`; gespeichert in `activities.failure_code` bzw.
  `failureCode` (Firestore). Felder für die Übersetzung (`reason.details`)
  landen in `FailedNode.failureDetails`, gespeichert in
  `activities.failure_details_json` bzw. `failureDetails`. Der Client
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
