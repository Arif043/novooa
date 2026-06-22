# Feature: Arbeitspläne

> **Stub** — dieses Feature ist noch nicht implementiert. Es wird in
> `lib/root_page.dart` als Tab „Arbeitspläne" angekündigt.

Verwandt: [`../architecture.md`](../architecture.md) ·
[`aufgabe.md`](./aufgabe.md) ·
[`aktivitaeten.md`](./aktivitaeten.md)

## Zweck

Verwalten gespeicherter und veröffentlichter Aufgaben. Übersicht statt Editor:
Liste, Status, Versionen, Veröffentlichung.

## Verantwortlichkeiten (geplant)

- Liste aller `TaskDefinition`s einer Nutzer:in.
- Statusanzeige: Entwurf, veröffentlicht, archiviert.
- Versionshistorie und Diff zwischen Versionen.
- Veröffentlichen / Zurückziehen.
- Duplizieren als Vorlage.

## Offene Fragen

- **Versionsmodell:** Lineare Versionen oder Branch + Merge?
- **Freigabe-Workflow:** Wer darf eine Aufgabe veröffentlichen — nur der
  Autor, oder ein Team?
- **Konflikte:** Wie wird mit parallelen Bearbeitungen umgegangen?

## Status

Noch nicht gestartet. Sobald die Firestore-Persistenz für `TaskDefinition`
verfügbar ist (siehe
[`../architecture.md#persistenz`](../architecture.md#persistenz)), kann dieses
Feature starten.