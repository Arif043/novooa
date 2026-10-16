# Jobs und Schritte über den Run (0012)

> `task_run_jobs` und `task_run_steps` speichern keine `team_id`; das Team ergibt sich über `run_id` aus `task_runs`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Pro Run gibt es einen Queue-Job; ein Schrittergebnis ist durch `run_id` +
  `step_path` identifiziert.
- Schreibzugriffe prüfen die Teamzugehörigkeit des Runs in der Transaktion;
  Lesen, Löschen und Job-Abschluss filtern über dessen Team.
- Beanspruchen oder Aufgeben eines Jobs liefert die Team-ID per
  `UPDATE … RETURNING` im selben Statement.
- Run löschen entfernt Jobs und Schritte per Kaskade.
- Die Migration erhält Lease-Zustand, Versuche, Zeitpunkte und `result_json`.

## Siehe auch

- [Task-Run-Warteschlange](./task-run-warteschlange.md)
- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
