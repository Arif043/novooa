# Feature: Zeitplan

> **Stub** — dieses Feature ist noch nicht implementiert. Es wird in
> `lib/root_page.dart` als Tab „Zeitplan" angekündigt.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Zeit- und event-gesteuerte Auslöser für Aufgaben. Hier konfigurieren
Nutzer:innen, **wann** eine Aufgabe läuft, ohne den Workflow selbst zu
bearbeiten.

## Verantwortlichkeiten (geplant)

- Trigger-Typen: Uhrzeit (einmalig / wiederkehrend), Intervall, manuell,
  Event, Webhook.
- Pro Aufgabe eine Trigger-Liste.
- Cron-UI statt Rohausdruck für Endnutzer:innen (vgl. Samsung Routines).
- Anzeige der nächsten geplanten Ausführung.
- Pause / Reaktivieren pro Trigger.

## Offene Fragen

- **Backend:** Cloud Scheduler vs. Genkit-Interrupt-Wartemechanismus.
- **Granularität:** Können einzelne Knoten andere Trigger haben als der
  gesamte Workflow, oder gilt ein Trigger immer für die ganze Aufgabe?
- **Konflikte:** Verhalten bei überlappenden Ausführungen (Rate-Limit,
  Skip-if-running).
- **Sicherheit:** Webhook-Authentifizierung (Signatur, Token).

## Status

Noch nicht gestartet. Detailtiefe folgt, sobald die ersten Trigger-Use-Cases
klar sind.