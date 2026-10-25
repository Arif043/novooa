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

## Feld „Bild“

- Feldtyp `image`: Die Person fügt beim Ausfüllen ein Bild hinzu. Ein
  Formular kann Bild und Angaben in einem Schritt abfragen (z. B. Beleg plus
  Betrag).
- **Quelle wählt der Client**, nicht der Baustein: Kamera, Galerie und, wo die
  Plattform es kann, „Dokument scannen“
  ([Dokumentenscanner](../index/dokumentscanner.md)).
- Der Client lädt das Bild als Team-Datei hoch und sendet in `formValues` nur
  dessen `fileId`. Das Backend lädt die Metadaten selbst, akzeptiert nur
  `image/*` und liefert für das Feld einen Wert vom Typ `media`
  (`fileId`, `versionId`, `displayName`, `contentType`, `sizeBytes`).
- Den früheren Baustein „Bild anfordern“ (`mediaInput`) gibt es nicht mehr;
  gespeicherte Aufgaben damit werden nicht umgewandelt und laufen erst wieder,
  wenn der Baustein durch ein Formular ersetzt ist.

## Siehe auch

- [Freigaben und Pausen](./freigaben-und-pausen.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
