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

## Verantwortlichkeiten (geplant)

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
- eine abschließende Task-Aktivität `succeeded` oder `failed`.

Persistenz:

```text
teams/{teamId}/taskRuns/{runId}
teams/{teamId}/activities/{activityId}
```

Der Flutter-Client liest die letzten Aktivitäten über
`FirestoreTaskActivityRepository` aus `teams/personal_<uid>/activities`.

## UI

`ActivityPage` zeigt die zuletzt erfassten Aktivitäten im Root-Tab
„Aktivitäten". Die Seite lädt über `ActivityCubit` und `ListTaskActivities`
und behandelt Loading, Fehler, Empty State und die erfolgreiche Liste.

## Offene Fragen

- **Quelle:** Genkit-Telemetrie (Cloud Trace / Cloud Logging) oder eigene
  Firestore-Sammlung `runs`? Hybrid voraussichtlich.
- **Live-Streaming:** Trace-Aktualisierung während ein Run läuft (SSE?
  Firestore-Listener?).
- **Freigabe-UX:** Inline im Run-Detail oder eigener Tab?
- **PII:** Outputs können sensible Daten enthalten — Filterung / Maskierung
  vor Anzeige klären.

## Status

Grundlegendes Activity-Tracking mit Firestore-Persistenz ist implementiert.
Live-Streaming, Filter und Genkit-Telemetrie-Anbindung stehen noch aus.
