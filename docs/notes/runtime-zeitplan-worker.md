# Zeitplan-Worker der Runtime

> In Standalone wertet `PollingTaskTriggerWorker` fällige Zeitpläne alle 30 Sekunden aus.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md) · [Zeitplan](../index/zeitplan.md)

Er erzeugt Runs über denselben Scheduling-Use-Case wie die Cloud und schreibt
den nächsten Ausführungszeitpunkt atomar in SQLite fort. Die Runs landen in
der [Task-Run-Warteschlange](./task-run-warteschlange.md).

Das Gegenstück in der Cloud ist der minütliche
[Worker für fällige Auslöser](./faellige-ausloeser-worker.md).

## Siehe auch

- [Materialisierte nächste Ausführung](./naechste-ausfuehrung-materialisiert.md)
