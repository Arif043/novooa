# Schleifenschutz zur Laufzeit

> Ein Lauf trägt seine Ursachenkette; ein Auslöser, der schon darin steht, startet nicht erneut.

Gehört zu: [Zeitplan](../index/zeitplan.md)

Aufgaben können sich über Datei-Auslöser gegenseitig oder selbst starten.
Zur Laufzeit gilt deshalb eine strenge Regel (Vermeidung, analog zum
Deadlock):

- Jeder Lauf trägt `triggerChain` im Input: die IDs aller Ereignis-Auslöser,
  die ihn mittelbar gestartet haben.
- Der Decorator `TriggerChainTeamFileStore` hängt die Kette an jede
  Schreiboperation des Laufs; sie landet im `FileEvent`.
- `DispatchFileEvent` überspringt einen Auslöser, dessen ID schon in der
  Kette steht. Schon die erste Wiederholung wird verhindert.

Das Überspringen erscheint als „Schleife verhindert“ im Anwendungsprotokoll.
Es gilt für alle Datei-Quellen, auch für Läufe, die ein Nachrichten-Auslöser
gestartet hat.

## Siehe auch

- [Schleifenschutz zur Entwurfszeit](./schleifenschutz-entwurfszeit.md) — die statische Ergänzung
- [Datei-Ereignisse lösen Aufgaben aus](./datei-ereignisse-dispatch.md)
