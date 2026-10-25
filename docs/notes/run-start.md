# Run starten

> Der Client startet eine Aufgabe; das Backend legt einen Run an, reiht ihn ein und gibt sofort dessen ID zurück, ausgeführt wird asynchron im Worker.

Gehört zu: [Aufgabe](../index/aufgabe.md)

`POST /v1/task-runs` erzeugt den Run und reiht ihn in die
[Task-Run-Warteschlange](./task-run-warteschlange.md) ein.

```ts
input:  { taskId: string; context?: string }
output: { runId: string; taskId: string; status: "queued" }
```

Der Worker führt den Graphen topologisch aus; Hauptgraph, Bedingungszweige
und eingebettete Graphen nutzen dieselbe Topologie. Die
`NodeExecutorRegistry` ordnet jedem Primitive eine Strategy zu; nicht
registrierte werden mit `status: "skipped"` gespeichert.

Aktivitäten: eine beim Start, je eine pro Knoten und ein abschließender
Erfolgs- oder Fehlerstatus. Der Client liest sie live.

## Siehe auch

- [Laufzeitgrenzen der Ausführung](./ausfuehrung-laufzeitgrenzen.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
- [Lokale Ausführung](./lokale-ausfuehrung.md)
