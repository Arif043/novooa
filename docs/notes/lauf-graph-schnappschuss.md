# Graph-Schnappschuss eines Laufs

> Ein Lauf speichert die Aufgabe, wie sie beim Start war, und führt Start und Fortsetzen damit aus — spätere Änderungen an der Aufgabe wirken erst auf neue Läufe.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- Beim Einreihen legt `enqueueTaskRun` Titel, Ziel, Knoten und Kanten in
  `task_runs.graph_snapshot_json` ab (Migration `0030`).
- Der Worker führt den Start und das Fortsetzen nach einer
  [Freigabe](./freigaben-und-pausen.md) aus dem Schnappschuss aus. Früher
  wurde die Aufgabe beim Fortsetzen neu geladen; ein wartender Lauf lief dann
  mit einer inzwischen geänderten Aufgabe weiter.
- Läufe von vor `0030` (oder mit einem Schnappschuss, den das heutige Schema
  nicht mehr liest) laden weiter die gespeicherte Aufgabe.
- `GET /v1/task-runs/:runId/graph` liefert den Schnappschuss (`404` ohne
  ihn) — Grundlage der geplanten Seite „Ergebnisse“, die den Lauf als Graph
  mit echten Werten und [Folgen](./lauf-effekte.md) zeigt.

## Siehe auch

- [Folgen eines Laufs](./lauf-effekte.md)
- [Run starten](./run-start.md)
