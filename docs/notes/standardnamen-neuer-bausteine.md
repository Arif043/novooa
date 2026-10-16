# Standardnamen neuer Bausteine

> Namen, Titel und Beschreibung eines neuen Bausteins folgen der App-Sprache beim Anlegen und werden gespeichert; ein späterer Sprachwechsel benennt nichts um.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Quelle: Port `NodeTextDefaults` (`domain/services`), Umsetzung
  `LocalizedNodeTextDefaults`. `{{…}}`-Referenzen bleiben dadurch stabil.
- Namen sind ASCII (`pruefung`, nicht `prüfung`), weil
  `_normalizedOutputName` Nicht-`\w`-Zeichen entfernt, und beginnen groß.
- Der erste Baustein einer Art hat keine Nummer, ab dem zweiten der nächste
  freie Name: `Input`, `Input2` (en) / `Eingabe`, `Eingabe2` (de);
  `SendEmail` / `SendenEmail`.
- Prompt-Bausteine heißen nach Ausgabetyp: Freitext „Text“, Entscheidung
  „Antwort“ (`decisionOutputBase`; en „Text“/„Answer“, tr „Metin“/„Cevap“).
  Beim Wechsel auf oder weg von „Entscheidung“ wird der Hauptwert immer auf den
  neuen Standardnamen gesetzt (bei Kollision nummeriert), auch wenn er
  umbenannt war.
- Technische Schlüssel der Werte (`recipient`, `sender` …) bleiben englisch
  (Datenvertrag); ihre Standardnamen stehen unter
  `task_builder.output_field_names`.

Ein Test in `test/core/localization/translations_test.dart` erzwingt
`^[A-Z][A-Za-z0-9_]*$` für alle Sprachen.

## Siehe auch

- [Entscheidungs-Prompt und Zweige](./entscheidungs-prompt-zweige.md)
- [Flacher Namensraum der Werte](./flacher-werte-namensraum.md)
