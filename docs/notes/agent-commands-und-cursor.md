# Commands und Agent-Cursor

> Der Agent liefert nur fachliche Commands; Auswählen, Hinfahren und Tippen inszeniert der Client selbst mit einem sichtbaren Cursor.

Gehört zu: [KI-Agent](../index/ki-agent.md)

| Command | Argumente | Wirkung |
| --- | --- | --- |
| `renameTask` | `title` | Aufgabe umbenennen |
| `addNode` | `primitive`, `kind`, `ref`, Feldwerte (`title`, `value`, `instruction`, …) | Baustein anlegen und befüllen |
| `configureNode` | `nodeRef`, `fields` | Eingabemaske eines Bausteins befüllen |

- `ref` ist plan-lokal: Node-IDs entstehen erst beim Ausführen, daher zeigt
  `configureNode.nodeRef` auf das `ref` eines `addNode` im selben Plan.
- Erlaubte Feldschlüssel (`NodeFieldKey`): `title`, `description`,
  `outputName`, `value`, `instruction`, `modelId`, `recipient`, `message`,
  `script`; andere verwirft das Backend. `outputName` ist der
  Name des Hauptwerts (Client: `WorkflowOutput` mit Schlüssel `value`).
- `addNode` mit `primitive: script` trägt `script`.
- Für Anbieter wählt `kind` den Kanal; deaktivierte Anbieter erzeugen keinen
  Baustein.

**Cursor:** Beim Ausführen reicht `AssistantActionPlan` den
`AgentCursorPerformer` (aus `AgentCursorScope`) an den Executor. Aktionen mit
`CursorAwarePlanAction` bedienen die Oberfläche sichtbar; `NodeFieldPlayer`
wählt den Baustein, fährt zum Feld (`AgentCursorAnchor`) und tippt
schrittweise in den Cubit. Fehlt ein Anker oder sind Animationen reduziert,
springt der Cursor bzw. entfällt — die Änderung hängt nie am Cursor. Der
Cursor gehört zum Aufgabenstudio (`TaskBuilderShellFrame`). Der Cursor ist Noovi in der Pose `fly`
(`AgentCursorNoovi`), siehe [Noovi, das Maskottchen](./noovi-maskottchen.md).

Offen: `configureNode` für bestehende Bausteine (der Client müsste deren IDs
und Werte mitsenden), `connectNodes`, `removeNode`, `updateTaskObjective`.

## Siehe auch

- [Agent ohne Modell testen (`/mock`)](./agent-mock.md)
- [Änderungspläne des Agenten](./agent-aenderungsplaene.md)
