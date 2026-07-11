# Feature: Zeitplan

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Zeit- und event-gesteuerte Auslöser für Aufgaben. Nutzer:innen konfigurieren
hier, **wann** eine Aufgabe läuft, ohne den Workflow selbst zu bearbeiten.

Der erste umgesetzte Scope sind zeitbasierte Trigger. Event-Trigger wie
„E-Mail empfangen“ oder „Datei erstellt“ bleiben im Modell vorgesehen, werden
aber noch nicht in der UI angeboten.

## Datenmodell

Trigger liegen team-scoped unter:

```text
teams/{teamId}/taskTriggers/{triggerId}
```

Dokument:

```ts
{
  id: string,
  teamId: string,
  createdByUid: string,
  taskId: string,
  taskTitle: string,
  type: "schedule",
  enabled: boolean,
  config: {
    kind: "once" | "daily" | "weekly",
    timezone: "Europe/Berlin",
    runAt?: Timestamp,
    timeOfDay?: "09:00",
    weekdays?: number[]
  },
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

`nextRunAt` ist bewusst materialisiert, damit der Backend-Worker fällige
Trigger effizient per Query finden kann.

## UI

Die Seite `Zeitplan` zeigt Trigger als Kacheln. Jede Kachel enthält:

- Aufgabe
- Trigger-Regel
- Aktiv/Pausiert-Schalter
- nächste Ausführung
- Löschen-Aktion

Der Dialog „Trigger hinzufügen“ bietet aktuell:

- einmalig
- täglich
- wöchentlich

Cron-Ausdrücke werden nicht direkt im UI eingegeben. Die UI erzeugt einfache
strukturierte Konfigurationen, aus denen Backend und Client `nextRunAt`
berechnen.

## Backend

`runDueTaskTriggersWorker` läuft jede Minute und liest fällige Trigger über:

```text
collectionGroup("taskTriggers")
  where enabled == true
  where nextRunAt <= now
```

Für jeden fälligen Trigger:

1. Aufgabe aus `teams/{teamId}/tasks/{taskId}` laden.
2. Bei `policy.ifRunning == "skipIfRunning"` aktive Runs derselben Aufgabe
   überspringen.
3. `taskRuns/{runId}` über dieselbe Queue-Struktur erzeugen wie manuelle Runs.
4. `lastRunAt`, `lastRunId` und `nextRunAt` am Trigger aktualisieren.
5. Einmalige Trigger nach Ausführung deaktivieren.

Der erzeugte `taskRun` enthält zusätzlich:

```ts
{
  source: "trigger",
  triggerId: string,
  triggerType: "schedule"
}
```

Lokal kann der Worker gegen den Functions Emulator manuell ausgelöst werden:

```bash
npm --prefix functions run schedule:run:local
```

Der Emulator exportiert scheduled/background Functions lokal mit `-0`-Suffix,
daher ruft der Script `runDueTaskTriggersWorker-0` auf.

## Firestore

Security Rules erlauben Team-Mitgliedern Lesen, Erstellen, Aktualisieren und
Löschen von `taskTriggers`. Die Rules validieren den Zeitplan-Trigger als
Prototyp inklusive `config`, `policy`, Team-Scope und existierender Aufgabe.

Für die Worker-Query ist ein Composite Index in `firestore.indexes.json`
definiert:

```text
collectionGroup: taskTriggers
enabled ASC, nextRunAt ASC
```

## Nächste Schritte

- Bearbeiten-Dialog für bestehende Trigger ergänzen.
- Event-Trigger `fileCreated` auf Storage-/Firestore-Dateiversionen abbilden.
- E-Mail-Trigger erst nach echter Mail-Provider-Integration modellieren.
- Team-Rollen später auf Trigger-Verwaltung anwenden.
