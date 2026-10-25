# Schritt-Journal (Checkpointing)

> Die Runtime speichert das Ergebnis jedes ausgeführten Bausteins; ein nach Absturz wiederholter Run übernimmt diese Ergebnisse, statt Bausteine erneut auszuführen.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Tabelle `task_run_steps`; Port `TaskRunStepJournal`, Adapter
  `SQLiteTaskRunStepJournal`.
- Der Graph läuft normal; Werte, Verzweigungen und übersprungene Zweige
  ergeben sich neu.
- **Schritt-Key = Idempotency-Key:** `runId` + Schritt-Pfad
  (`TaskRunStepKey`). Top-level die Node-ID, in Teilgraphen mit
  Container-Baustein und Aufrufindex, z. B. `schleife:3/mail` für die vierte
  Iteration. Abgeschlossene Iterationen laufen nicht erneut.
- Gespeichert werden nur ausgeführte Bausteine; wartende Freigaben setzen über
  den Resume-Zustand fort.
- Nach Erfolg, Fehler oder Ablehnung wird das Journal gelöscht, beim Löschen
  des Runs per Kaskade.
- **Restfenster:** Stürzt der Prozess nach dem Effekt eines Bausteins, aber vor
  dem Speichern ab, läuft genau dieser Baustein erneut.

## Siehe auch

- [Task-Run-Warteschlange](./task-run-warteschlange.md)
- [Jobs und Schritte über den Run (0012)](./sqlite-run-abhaengige-normalisiert.md)
