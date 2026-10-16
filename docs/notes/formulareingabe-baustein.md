# Formulareingabe (`dialogInput`)

> Der Baustein pausiert den Run und fragt typisierte Felder per Formular ab; jedes Feld wird danach ein eigener Wert.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Der Executor speichert Feldname, Datentyp und Optionen in `resumeState` und
  sendet eine Benachrichtigung.
- Beim Bestätigen kommen `formValues`; das Backend prüft alle gegen die
  gespeicherte Definition.
- Danach liefert der Knoten einen typisierten Output pro Feld (Schlüssel =
  Feldname). Feldnamen sind Beschriftung und Schlüssel und müssen nur im
  Baustein eindeutig sein (`kundennummer`). In Templates gilt der Name aus
  `outputs` (bei Kollision `kundennummer2`).

## Siehe auch

- [Freigaben und Pausen](./freigaben-und-pausen.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
