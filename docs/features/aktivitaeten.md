# Feature: Aktivitäten

> Aktivitäten werden beim Ausführen von Aufgaben im Backend geschrieben und im
> Root-Tab „Aktivitäten" angezeigt.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`zeitplan.md`](./zeitplan.md)

## Zweck

Beobachtbarkeit und Freigaben. Nutzer:innen sehen hier, was passiert ist,
warum, und können an den Stellen eingreifen, an denen das Workflow pausiert
(`humanApproval`).

## Verantwortlichkeiten

- Run-Liste pro Aufgabe: Status, Start, Ende, Dauer, Tokens, Kosten.
- Trace-Detailansicht: pro Knoten Input, Output, Modell-Aufruf.
- Freigabe-Warteschlange: alle Aufgaben, die auf `humanApproval` warten.
- Filter: nach Aufgabe, Status, Zeitraum, Trigger.
- Re-Run eines Runs mit gleichem Input.

## Aktueller Schnitt

Das Feature besitzt ein Domain-Modell für `TaskActivity`. Die Firebase
Functions schreiben pro Hintergrund-Run:

- eine Task-Aktivität `started` mit Run-ID und Eingabekontext,
- pro Baustein eine Node-Aktivität mit Status `succeeded`, `skipped` oder
  `waiting`,
- eine abschließende Task-Aktivität `succeeded` oder `failed`, sofern der Run
  nicht auf Freigabe wartet.

Persistenz:

```text
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
```

Der Flutter-Client liest die letzten Aktivitäten über
`FirestoreTaskActivityRepository` aus `teams/{teamId}/activities`.
Zusätzlich liest `FirestoreTaskRunRepository` die letzten TaskRuns aus
`teams/{teamId}/taskRuns`. `teamId` wird über `users/{uid}.teamId` aufgelöst,
damit die Tabs „Laufend“, „Freigabe“ und „Abgelehnt“ ohne aktive
Backend-Wartezeit gerendert werden.

Runs mit Status `waitingForApproval` enthalten für die Freigabe-UI:

```text
reviewInstruction  # Anweisung des Freigabe-Bausteins
reviewOutput       # editierbarer Output des vorherigen Bausteins
resumeState        # serialisierter Zwischenzustand für die Fortsetzung
```

## UI

`ActivityPage` zeigt Tabs für laufende Runs, Freigaben, abgelehnte Runs und
Historie. Freigaben werden als Kacheln dargestellt. Ein Klick öffnet einen
Dialog mit Instruction, editierbarem Output und Aktionen zum Ablehnen oder
Bestätigen. Bestätigung ruft `reviewTaskRunFlow` mit `decision: "approve"` auf,
setzt den Run auf `queued` und startet die Fortsetzung per Firestore-Trigger.
Ablehnung ruft denselben Flow mit `decision: "reject"` auf und verwirft den
Zwischenzustand.

## Offene Fragen

- **Quelle:** Genkit-Telemetrie (Cloud Trace / Cloud Logging) oder eigene
  Firestore-Sammlung `runs`? Hybrid voraussichtlich.
- **Live-Streaming:** Trace-Aktualisierung während ein Run läuft (SSE?
  Firestore-Listener?).
- **PII:** Outputs können sensible Daten enthalten — Filterung / Maskierung
  vor Anzeige klären.

## Status

Grundlegendes Activity-Tracking, Run-Tabs und Freigabe-Dialog sind
implementiert. Live-Streaming, Filter und Genkit-Telemetrie-Anbindung stehen
noch aus.
