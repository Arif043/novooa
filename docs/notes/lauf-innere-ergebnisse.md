# Innere Ergebnisse eines Laufs

> Auch Bausteine in Zweigen und Schleifenrunden hinterlassen eine Aktivität — mit umschließendem Baustein, Runde und dem gewählten Zweig.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- Zweige und Schleifen geben selbst nur ihr Gesamtergebnis zurück. Der
  Runner sammelt deshalb je Baustein, was in seinen Teilgraphen lief
  (`NestedRunCollector`), und hängt es als `nested` an das Ergebnis bzw. an
  den gescheiterten Baustein: ein Eintrag je Aufruf, bei Schleifen je Runde
  (`iteration`, ab 0); ein abgebrochener innerer Baustein steht als `failed`.
- Journal und Resume-Zustand tragen `nested` mit; eine Wiederholung zählt
  nichts doppelt.
- Gespeichert als eigene Zeilen in `activities` mit `parent_node_id`,
  `iteration` und `selected_branch_id` (Migration `0031`). Ein Zweig in einer
  Schleife erbt die Runde der Schleife.
- `GET /v1/activities` (Historie) zeigt weiter nur die oberste Ebene;
  `GET /v1/task-runs/:runId/activities` liefert alle Zeilen eines Laufs in
  Reihenfolge (höchstens 10 000).
- `GET /v1/task-runs` liefert zusätzlich `startedAt`, `completedAt`,
  `triggerType` und `startedBy`.

## Siehe auch

- [Seite „Ergebnisse“](./ergebnisse-seite.md)
- [Folgen eines Laufs](./lauf-effekte.md)
