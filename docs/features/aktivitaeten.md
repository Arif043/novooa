# Feature: Aktivitäten

> Aktivitäten werden beim Ausführen von Aufgaben im Backend geschrieben und im
> Root-Tab „Aktivitäten" angezeigt.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`zeitplan`](../index/zeitplan.md)

## Zweck

Beobachtbarkeit und Freigaben. Nutzer sehen hier, was passiert ist,
warum, und können an den Stellen eingreifen, an denen das Workflow pausiert
(`humanApproval`, `dialogInput`, `mediaInput`).

## Verantwortlichkeiten

- Run-Liste pro Aufgabe: Status, Start, Ende, Dauer, Tokens, Kosten.
- Trace-Detailansicht: pro Knoten Input, Output, Modell-Aufruf.
- Interaktions-Warteschlange: alle Aufgaben, die auf menschliche Freigabe,
  Formulareingabe oder Bildaufnahme warten.
- Filter: nach Aufgabe, Status, Zeitraum, Trigger.
- Re-Run eines Runs mit gleichem Input.

## Aktueller Schnitt

In Standalone wird seit SQLite-Migration `0014` die Team- und
Aufgabenzuordnung einer Aktivität über ihren Run aufgelöst. Aktivitäten
speichern dafür nur `run_id`; ein Fremdschlüssel verhindert verwaiste Einträge.
Schreibzugriffe prüfen die angegebenen Run-, Team- und Aufgabenbezüge atomar.
Titel, Ergebnisse und Konsolenprotokolle bleiben historische Snapshots.
Das Löschen einer Aufgabe erhält diese Historie; das explizite Löschen eines
Runs entfernt dessen Aktivitäten. Firestore behält die nachfolgende eigene
Speicherstruktur.

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

Runs mit Status `waitingForApproval` enthalten für die Interaktions-UI:

```text
interaction        # Art und Definition: Freigabe, Formular oder Medienaufnahme
reviewOutput       # editierbarer Output des vorherigen Bausteins
resumeState        # serialisierter Zwischenzustand für die Fortsetzung
```

## UI

`ActivityPage` zeigt Tabs für laufende Runs, Freigaben, abgelehnte Runs und
Historie. Die Historie listet nur Task-Aktivitäten. Die lokale Variante ergänzt
den Tab **Protokoll**. Er zeigt die letzten strukturierten Runtime-Ereignisse
aus SQLite; Laufaktivitäten und Anwendungsprotokoll bleiben getrennt. Ein Klick öffnet den
jeweiligen Durchlauf und zeigt dessen Node-Aktivitäten chronologisch mitsamt
den benannten Ausgabewerten. Werte werden entsprechend ihres Output-Typs
lesbar formatiert.
Interaktionen werden als Kacheln dargestellt. Ein Klick öffnet einen iOS-Dialog:
bei Freigaben mit editierbarem Output, bei `dialogInput` mit den definierten
Feldtypen und bei `mediaInput` mit einer Auswahl zwischen Galerie und Kamera (bei aktiver Option als Dokumentenscanner, siehe [`dokumentscanner.md`](./dokumentscanner.md)). Bestätigung ruft `reviewTaskRunFlow` mit `decision: "approve"` auf,
setzt den Run auf `queued` und startet die Fortsetzung per Cloud Task. Ablehnung
ruft denselben Flow mit `decision: "reject"` auf und verwirft den Zwischenzustand.

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
