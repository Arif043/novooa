# Aufgabe als Aggregat

> `TaskDefinition` ist ein immutable Aggregate Root; jede Mutation erzeugt per `copyWith` eine neue Instanz und wird sofort gespeichert.

Gehört zu: [Aufgabe](../index/aufgabe.md)

```
lib/features/task_builder/
├── domain/          # TaskDefinition, WorkflowNode, WorkflowEdge, Repository
├── infrastructure/  # Runtime-Mapping und Repositories
└── presentation/    # Builder-Cubit, Seite, Palette, Canvas, Panel
```

Invarianten:

- Node-IDs bleiben stabil.
- Höchstens ein selektierter Knoten.
- Kanten referenzieren nur vorhandene Knoten.
- Kanten bestimmen nur Reihenfolge und Verzweigung, keine Datenauswahl.

Autosave statt Speichern-Dialog: Jede Mutation geht direkt über
`TaskRepository.saveTask()`; der Cubit emittiert danach einen neuen
immutable State.

## Siehe auch

- [Bausteinkatalog](./bausteinkatalog.md)
- [Standardnamen neuer Bausteine](./standardnamen-neuer-bausteine.md)
- [Layout des Aufgabenstudios](./aufgabenstudio-layout.md)
