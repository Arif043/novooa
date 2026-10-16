# Task-Run-Warteschlange

> Runs laufen über eine haltbare SQLite-Jobqueue; der Worker wird beim Einreihen sofort geweckt und pollt nicht.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Nach einem erfolgreichen Enqueue wird `TaskRunQueueWorker` direkt
  benachrichtigt, arbeitet verfügbare Jobs seriell ab und bestätigt
  erfolgreiche Ausführungen.
- Beim Start werden persistierte Jobs einmal abgearbeitet.
- Nach einem Prozessabsturz werden abgelaufene Leases erneut beansprucht,
  insgesamt höchstens drei Versuche.
- Für spätere Fälligkeiten setzt der Worker nur einen einmaligen Timer auf den
  gespeicherten Zeitpunkt, kein Intervall-Polling.
- Ein gescheiterter Baustein lässt den Job **nicht** scheitern (der Lauf ist
  festgehalten, eine Wiederholung würde Nebenwirkungen erneut auslösen). Nur
  unerwartete Fehler (Laden, Speichern, ungültiger Plan) werfen weiter und
  werden bis zu dreimal wiederholt.
- Ohne gültige Lizenz starten Task- und Trigger-Worker keine Jobs.

## Siehe auch

- [Fehlgeschlagene Bausteine in den Aktivitäten](./baustein-fehler-aktivitaeten.md)
- [Jobs und Schritte über den Run (0012)](./sqlite-run-abhaengige-normalisiert.md)
- [Zeitplan-Worker der Runtime](./runtime-zeitplan-worker.md)
