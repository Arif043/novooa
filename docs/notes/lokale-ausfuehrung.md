# Lokale Ausführung

> Mit `NOVOOA_RUNTIME=standalone` spricht der Client nur die Runtime an; Runs, Zeitpläne und Freigaben laufen im Container, auch ohne geöffnete App.

Gehört zu: [Aufgabe](../index/aufgabe.md)

```bash
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

- `POST /v1/task-runs` und `POST /v1/task-runs/review` liefern bei fachlich
  ungültiger Anfrage `400` mit stabilem Failure-Vertrag:

  ```ts
  { failure: { code: "invalidTaskId", message: "taskId muss ein nicht leerer String sein." } }
  ```

- Runs laufen seriell über die
  [Task-Run-Warteschlange](./task-run-warteschlange.md) und setzen nach
  einem Absturz über das [Schritt-Journal](./schritt-journal.md) fort.
- Cloud-gebundene Funktionen (Twilio-Kanäle, Push ohne Relay) stehen nur über
  die Relays bereit, siehe [Lokale Runtime](../index/lokale-runtime.md).

## Siehe auch

- [Run starten](./run-start.md)
- [Runtime-API des nativen Clients](./runtime-client-api.md)
