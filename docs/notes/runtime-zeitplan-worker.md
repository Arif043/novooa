# Zeitplan-Worker der Runtime

> In der Runtime wertet `PollingTaskTriggerWorker` fällige Zeitpläne alle 30 Sekunden aus.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md) · [Zeitplan](../index/zeitplan.md)

Er erzeugt Runs über den Scheduling-Use-Case und schreibt den nächsten
Ausführungszeitpunkt atomar in SQLite fort. Die Runs landen in
der [Task-Run-Warteschlange](./task-run-warteschlange.md).

## Siehe auch

- [Materialisierte nächste Ausführung](./naechste-ausfuehrung-materialisiert.md)
