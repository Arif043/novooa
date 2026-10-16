# Kern-Entitäten

> Die zentralen Domain-Typen von Aufgaben und Daten und wo sie liegen.

Gehört zu: [Architektur](../index/architektur.md)

| Entität | Datei | Rolle |
| --- | --- | --- |
| `TaskDefinition` | `lib/features/task_builder/domain/entities/task_definition.dart` | Aggregate Root eines Workflows |
| `WorkflowNode` | `lib/features/task_builder/domain/entities/workflow_node.dart` | Ein Baustein (Primitive-Instanz) |
| `WorkflowEdge` | `lib/features/task_builder/domain/entities/workflow_edge.dart` | Gerichtete Kante |
| `NodeId` | `lib/features/task_builder/domain/entities/workflow_node.dart` | Value Object (`==` + `hashCode`) |
| `WorkflowPrimitive` | `lib/features/task_builder/domain/entities/workflow_node.dart` | Enum der Bausteintypen |
| `DocumentStore` | `functions/src/features/data/domain/repositories/document-store.ts` | Port für team-scoped Datensätze |

## Siehe auch

- [Aufgabe als Aggregat](./aufgabe-aggregat.md)
- [Bausteinkatalog](./bausteinkatalog.md)
- [Datensammlungen: Fachmodell](./datensammlungen-fachmodell.md)
