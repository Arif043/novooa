# Feature: Aktivitäten

> **Stub** — dieses Feature ist noch nicht implementiert. Es wird in
> `lib/root_page.dart` als Tab „Aktivitäten" angekündigt.

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

## Offene Fragen

- **Quelle:** Genkit-Telemetrie (Cloud Trace / Cloud Logging) oder eigene
  Firestore-Sammlung `runs`? Hybrid voraussichtlich.
- **Live-Streaming:** Trace-Aktualisierung während ein Run läuft (SSE?
  Firestore-Listener?).
- **Freigabe-UX:** Inline im Run-Detail oder eigener Tab?
- **PII:** Outputs können sensible Daten enthalten — Filterung / Maskierung
  vor Anzeige klären.

## Status

Noch nicht gestartet. Hängt von `enableFirebaseTelemetry()` und dem
Trigger-System ab (siehe
[`../architecture.md#telemetrie`](../architecture.md#telemetrie)).