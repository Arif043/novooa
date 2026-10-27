# Import und Export von Datensammlungen

> Eine Sammlung lässt sich als CSV oder JSON herunterladen und aus einer CSV- oder JSON-Datei füllen; die Runtime liest und schreibt beide Formate, die App zeigt vor dem Import eine Vorschau.

Gehört zu: [Daten](../index/daten.md)

- **Ein Codec in der Runtime** (`domain/services/document-table-codec.ts`,
  `csv-table.ts`, `document-field-names.ts`): Export und Import nutzen dieselben
  Regeln; die App kennt die Formate nicht.
- **Export** (`POST /v1/data/collections/{name}/export` mit `format`, Suche,
  Filtern und Sortierung): alle Treffer, seitenweise gelesen — nicht nur die
  500 der Ansicht. Datei `<Sammlung>.csv` bzw. `.json`.
  - CSV: Komma, CRLF, UTF-8 mit BOM (Excel erkennt so Umlaute), Spalten =
    alle Felder alphabetisch, verschachtelte Werte als JSON-Text.
  - JSON: Liste der Felder je Datensatz; lässt sich unverändert importieren.
- **Import** (`POST …/import?format=csv|json&dryRun=true|false`, Datei als
  `application/octet-stream`): erst Vorschau, dann Übernahme.
  - CSV mit Kopfzeile; Trennzeichen Komma oder Semikolon (deutsches Excel),
    erkannt an der ersten Zeile; Anführungszeichen und Zeilenumbrüche in
    Zellen nach RFC 4180.
  - JSON: Liste von Objekten.
  - Werte wie im Editor: `true`/`false` und Zahlen werden erkannt, sonst Text;
    Zahlen mit führender Null (Postleitzahlen) bleiben Text; leere Zellen
    lassen das Feld weg.
  - Spaltennamen werden zu sortier- und filterbaren Feldnamen: Umlaute
    umschreiben (`ä→ae`), Akzente entfernen, sonst `_`, eindeutig mit `_2`.
    Die Vorschau nennt jede Umbenennung.
  - Vorschau: Anzahl, Felder, Umbenennungen, bis zu fünf Beispiele,
    Probleme mit Zeile oder Eintrag. Mit Problemen übernimmt die Runtime
    nichts (422).
  - Übernahme hängt an (kein Abgleich über IDs) — in einer Transaktion,
    alle oder keiner (`createMany`).
- **Grenzen:** Datei höchstens 5 MB (App prüft vor dem Upload, Runtime
  antwortet 413), höchstens 5 000 Datensätze je Import.
- Rundlauf: Ein CSV-Export kann Text wie `"42"` beim Re-Import als Zahl
  lesen; JSON bewahrt die Wertarten.

## Siehe auch

- [Datenbank-Seite](./datenbank-seite.md)
- [Datensammlungen: Fachmodell](./datensammlungen-fachmodell.md)
