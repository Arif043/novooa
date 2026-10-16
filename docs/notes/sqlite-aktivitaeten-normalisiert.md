# Aktivitäten über den Run (0014)

> Aktivitäten speichern weder `team_id` noch `task_id`; beides ergibt sich über `run_id`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- `run_id` ist Fremdschlüssel auf `task_runs`; Index auf `run_id` und
  `created_at` für die Reihenfolge.
- Adapter und HTTP-Route prüfen Run, Team und Aufgabe in derselben
  Transaktion; fehlende oder widersprüchliche Bezüge ergeben `400`.
- Titel, Ein-/Ausgaben, Status, Dauer, Zeitpunkte, Konsolenprotokolle und
  JSON-Ergebnisse bleiben historische Fakten.
- Aufgabe ändern oder löschen erhält Runs und Aktivitäten; einen Run löschen
  entfernt seine Aktivitäten per Kaskade.
- HTTP- und Domain-Objekte enthalten weiter die abgeleitete Aufgaben-ID.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Fehlgeschlagene Bausteine in den Aktivitäten](./baustein-fehler-aktivitaeten.md)
