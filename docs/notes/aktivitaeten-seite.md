# Aktivitäten-Seite

> `ActivityPage` zeigt laufende Runs, Freigaben, abgelehnte Runs und die Historie; Standalone ergänzt den Tab „Protokoll“.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- **Historie:** nur Task-Aktivitäten; ein Klick öffnet den Durchlauf mit
  seinen Node-Aktivitäten chronologisch samt benannten Werten, formatiert nach
  Output-Typ (inklusive Script-Ausgabe, siehe
  [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)).
- **Protokoll** (Standalone): die letzten strukturierten Runtime-Ereignisse
  aus dem [Anwendungsprotokoll](./anwendungsprotokoll.md), getrennt von
  Laufaktivitäten.
- **Interaktionen** als Kacheln; ein Klick öffnet einen iOS-artigen Dialog:
  Freigabe mit editierbarem Output, `dialogInput` mit den Feldtypen,
  `mediaInput` mit Galerie oder Kamera (optional
  [Dokumentenscanner](../index/dokumentscanner.md)).
- Bestätigen ruft `reviewTaskRunFlow` mit `decision: "approve"`, setzt den Run
  auf `queued` und setzt per Cloud Task fort; Ablehnen mit `"reject"` verwirft
  den Zwischenzustand.

## Siehe auch

- [Aktivitäten eines Runs](./aktivitaeten-schreiben.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
