# Worker für fällige Auslöser

> `runDueTaskTriggersWorker` läuft jede Minute und startet fällige Zeitplan-Auslöser als normale `taskRuns`.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Query:

```text
collectionGroup("taskTriggers")
  where enabled == true
  where nextRunAt <= now
```

Pro fälligem Auslöser:

1. Aufgabe aus `teams/{teamId}/tasks/{taskId}` laden.
2. Bei `policy.ifRunning == "skipIfRunning"` überspringen, solange ein Lauf
   derselben Aufgabe aktiv ist.
3. `taskRuns/{runId}` über dieselbe Queue wie manuelle Läufe erzeugen.
4. `lastRunAt`, `lastRunId` und `nextRunAt` aktualisieren.
5. Einmalige Auslöser danach deaktivieren.

Der Lauf trägt seine Herkunft:

```ts
{ source: "trigger", triggerId: string, triggerType: "schedule" | "event" }
```

Lokal gegen den Functions Emulator:

```bash
npm --prefix functions run schedule:run:local
```

Der Emulator exportiert scheduled Functions mit `-0`-Suffix; das Skript ruft
deshalb `runDueTaskTriggersWorker-0` auf.

## Siehe auch

- [Materialisierte nächste Ausführung](./naechste-ausfuehrung-materialisiert.md)
- [Aufgabe: Ausführung](../features/aufgabe-ausfuehrung.md) — Runner und Queue
