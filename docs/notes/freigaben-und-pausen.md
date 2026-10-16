# Freigaben und Pausen

> `humanApproval`, `dialogInput` und `mediaInput` halten den Run mit `waitingForApproval` an; eine Entscheidung setzt den Graphen fort oder lehnt ab.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Der Zwischenstand liegt in `resumeState` am Run.
- Freigabe ersetzt den Output des wartenden Knotens und setzt fort; Ablehnung
  markiert den Run als `rejected`.

```ts
reviewTaskRunFlow:
input:  { runId: string; decision: "approve" | "reject"; output?: string; formValues?: Record<string, unknown> }
output: { runId: string; status: "queued" | "rejected" }
```

Standalone: `POST /v1/task-runs/review`. Wartet eine Aufgabe, geht eine
Push-Benachrichtigung raus.

## Siehe auch

- [Formulareingabe](./formulareingabe-baustein.md)
- [Bild anfordern](./bild-anfordern-baustein.md)
- [Push-Benachrichtigungen in Standalone](./push-standalone.md)
