# Lokale Ausführung

> Der Client spricht nur die Runtime an; Runs, Zeitpläne und Freigaben laufen im Container, auch ohne geöffnete App.

Gehört zu: [Aufgabe](../index/aufgabe.md)

```bash
flutter run -d macos
```

- `POST /v1/task-runs` und `POST /v1/task-runs/review` liefern bei fachlich
  ungültiger Anfrage `400` mit stabilem Failure-Vertrag:

  ```ts
  { failure: { code: "invalidTaskId", message: "taskId muss ein nicht leerer String sein." } }
  ```

- Runs laufen seriell über die
  [Task-Run-Warteschlange](./task-run-warteschlange.md) und setzen nach
  einem Absturz über das [Schritt-Journal](./schritt-journal.md) fort.
- Was Firebase braucht (Push, Postfächer, Aufgabenstudio-Agent), steht nur
  über die Relays bereit, siehe [Lokale Runtime](../index/lokale-runtime.md).

## Siehe auch

- [Run starten](./run-start.md)
- [Runtime-API des nativen Clients](./runtime-client-api.md)
