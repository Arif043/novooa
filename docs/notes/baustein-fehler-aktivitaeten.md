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
- Streng steigende Zeitstempel (ms) im SQLite-Aktivitäts-Store sichern die
  Reihenfolge.
- Die Lauf-Meldung erscheint nur dann als eigener Eintrag oben, wenn kein
  Baustein die Ursache war (etwa ein ungültiger Plan).
- Nach einer Freigabe werden nur neu hinzugekommene Ergebnisse geschrieben.

## Siehe auch

- [Task-Run-Warteschlange](./task-run-warteschlange.md)
- [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)
- [Aufgabe: Ausführung](../features/aufgabe-ausfuehrung.md)
