# Auslöser-Datenmodell

> Ein Auslöser (`taskTrigger`) startet genau eine Aufgabe, entweder nach Zeitplan (`schedule`) oder bei einem Ereignis (`event`).

Gehört zu: [Zeitplan](../index/zeitplan.md)

Auslöser liegen team-scoped unter `teams/{teamId}/taskTriggers/{triggerId}`:

```ts
{
  id: string,
  teamId: string,
  createdByUid: string,
  taskId: string,
  taskTitle: string,
  type: "schedule" | "event",
  enabled: boolean,
  config?: ZeitplanKonfiguration,     // nur bei type == "schedule"
  eventConfig?: EreignisKonfiguration, // nur bei type == "event"
  policy: {
    ifRunning: "skipIfRunning" | "startParallel"
  },
  nextRunAt?: Timestamp,
  lastRunAt?: Timestamp,
  lastRunId?: string,
  createdAt: Timestamp,
  updatedAt: Timestamp
}
```

`policy.ifRunning` entscheidet, ob ein fälliger Auslöser übersprungen wird,
solange noch ein Lauf derselben Aufgabe aktiv ist.

## Siehe auch

- [Zeitplan-Wiederholungsarten](./zeitplan-wiederholungsarten.md) — Aufbau von `config`
- [Ereignisziel eines Auslösers](./ausloeser-ereignisziel.md) — Aufbau von `eventConfig`
- [Materialisierte nächste Ausführung](./naechste-ausfuehrung-materialisiert.md) — warum `nextRunAt` gespeichert wird
- [Auslöser in der Datenbank der Runtime](./ausloeser-standalone-aufgabenbezug.md)
