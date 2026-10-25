# Aktivitäten-Seite

> `ActivityPage` zeigt laufende Runs, Freigaben, abgelehnte Runs und die Historie; Admins sehen zusätzlich den Tab „Protokoll“.

Gehört zu: [Aktivitäten](../index/aktivitaeten.md)

- **Historie:** nur Task-Aktivitäten; ein Klick öffnet den Durchlauf mit
  seinen Node-Aktivitäten chronologisch samt benannten Werten, formatiert nach
  Output-Typ (inklusive Script-Ausgabe, siehe
  [Script-Ausgabe im Protokoll](./script-ausgabe-protokoll.md)).
- **Gespräch der Mitarbeiter:** Hat eine Node-Aktivität ein Gespräch (Teamarbeit,
  auch bei Fehlern), zeigt sie den TextButton „Gespräch der Mitarbeiter
  anzeigen“. Er öffnet per `Navigator.push` die `TeamworkConversationPage`. Dort
  steht je Eintrag eine Karte mit dem Sprecher als Noovi-Avatar (Pose nach Art,
  Ring in seiner Farbe, siehe [Noovi](./noovi-maskottchen.md)): wer zu wem spricht, Art, Uhrzeit, ggf. Dauer und
  der ungekürzte Text, bei Aufträgen zusätzlich „Erwartetes Ergebnis“ und
  „Grenzen“. Farben nach Rolle: Orchestrator, Mitarbeiter, Prüfung, Fehler.
- **Protokoll** (nur Admins): die letzten strukturierten Runtime-Ereignisse
  aus dem [Anwendungsprotokoll](./anwendungsprotokoll.md), getrennt von
  Laufaktivitäten.
- **Interaktionen** als Kacheln; ein Klick öffnet einen iOS-artigen Dialog:
  Freigabe mit editierbarem Output, `dialogInput` mit den Feldtypen; ein
  Bildfeld bietet Kamera, Galerie und, wo möglich,
  [Dokument scannen](../index/dokumentscanner.md).
- Bestätigen ruft `POST /v1/task-runs/review` mit `decision: "approve"`,
  setzt den Run auf `queued` und reiht ihn wieder ein; Ablehnen mit `"reject"`
  verwirft den Zwischenzustand.

## Siehe auch

- [Aktivitäten eines Runs](./aktivitaeten-schreiben.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
- [Ausführung der Teamarbeit](./teamwork-ausfuehrung.md)
