# Layout des Aufgabenstudios

> Links die Baustein-Palette, in der Mitte die zoombare Leinwand, rechts ein Konfigurations-Overlay; darüber eine gemeinsame Kopfzeile.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- **Gestaltung:** Inter-Typografie und abgestufte Oberflächen aus
  [`DESIGN.md`](../DESIGN.md); `TaskBuilderTheme` bündelt das für Hell und
  Dunkel.
- **Kopfzeile:** Navigation über der Palette, editierbarer Aufgabentitel über
  der Leinwand, KI-Agent und Benachrichtigungen rechts.
- **Palette:** durchsuchbar, nach Kategorien gruppiert. Klick fügt ein;
  Drag-and-Drop oder die Plus-Aktion einer Karte wählt eine konkrete
  Anschlussstelle, auch in Verzweigungen und Schleifen. Auf schmalen Fenstern
  über „Bausteine“ eingeblendet.
- **Leinwand:** verschieb- und zoombar, kompakte Karten mit Typ und ID; Kanten
  mit Richtungspfeilen und Bedingungslabels; Unterpläne mit beschrifteten
  Verbindungen zum übergeordneten Baustein. Ändert sich der Plan, gleiten
  Karten und Kanten gemeinsam an ihren neuen Platz; entfernte Bausteine und
  Pfade blenden an ihrem alten Platz aus, neue blenden ein
  (`CanvasFrame`, 350 ms).
- **Tauschen:** Am Icon einer Karte lässt sich ein Baustein auf einen anderen
  ziehen; beide tauschen Platz und Kanten. Das geht im selben Plan, zwischen
  Hauptplan und Zweig, zwischen zwei Zweigen und mit dem Unterplan einer
  Schleife (`WorkflowNodeSwap`). Eine Bedingung oder Schleife kann nicht in
  ihren eigenen Unterplan wandern.
- **Overlay:** Klick auf eine Karte öffnet rechts die Konfiguration im selben
  Provider-Kontext (Editoren, Anhänge, Ausgabenamen, Werte); Änderungen wirken
  sofort; Schließen per Schaltfläche oder Escape.
- **Prinzipien:** Anlass statt technischer Konfiguration, Inline-Vorschau wo
  hilfreich, sofortiges Feedback, aussagekräftige Leer- und Fehlerzustände.

## Siehe auch

- [Anschlüsse auf der Leinwand](./leinwand-anschluesse.md)
- [Werte im Panel und auf der Leinwand](./werte-panel-und-leinwand.md)
- [Darstellung der Ausgabetypen](./ausgabetyp-darstellung.md)
