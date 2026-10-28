# Baustein „Für jedes Element“ (`forEach`)

> `forEach` führt einen eingebetteten Graphen seriell für jedes Element eines JSON-Arrays aus und liefert eine Liste der benannten Ergebnisse.

Gehört zu: [Aufgabe](../index/aufgabe.md) · [ML-Modelle](../index/ml-modelle.md)

```text
JSON value -> RFC-6901 pointer -> serielle Graph-Ausführungen -> strukturierte JSON-Liste
```

- Konfiguration: `itemsTemplate` (Feld „Liste“, Pflicht), `itemsPointer`
  (Feld „Elemente aus“) und eingebetteter Graph. Zuerst wird `itemsTemplate`
  aufgelöst, dann der Pointer auf diesen JSON-Wert angewandt: leer = ganzer
  Wert (z. B. wenn ein Modell direkt eine Liste liefert), `/regions` bei einem
  Objekt mit diesem Feld. Ein leeres Feld „Liste“ ergibt keine Liste — der
  Baustein scheitert mit einem Typfehler; es gibt keinen Rückfall auf den
  direkten Vorgänger.
- Jede Iteration bekommt `iteration` mit `index` und `value`
  (`{{iteration.value.bounds}}`, `{{iteration.index}}`). Der synthetische
  `value`-Vorgänger bleibt für Bausteine ohne eigene Zuordnung; echte Kanten
  haben Vorrang.
- Schreibgeschützter äußerer Kontext: `{{global.Eingabe}}`,
  `{{global.input.feld}}`; kurz `{{Eingabe}}`,
  sofern im Unterplan kein gleichnamiger Wert existiert.
- Ausgabe: je Element die benannten Werte aller ausgeführten Bausteine flach
  unter ihrem Namen, z. B. `{{Regionen.0.Erkenner.text}}`.
- Iterationen sind isoliert und laufen seriell; ein Fehler bricht mit dem
  Elementindex ab. Pausierende und verschachtelte `forEach` sind im Unterplan
  nicht zulässig.

Ausführung: `executeForEach` (Domain) validiert den Unterplan, läuft seriell
und fail-fast; RFC-6901-Auswertung und Regeln liegen in der Domain.

Kanten enthalten keine Datenauswahl (`fromOutput` wurde entfernt):
Nachfolger binden Werte über ihren eigenen Vertrag, damit der Datenfluss an
einer Stelle konfiguriert bleibt.

Offen: sichtbare Validierung (Pointer, leere Unterpläne, pausenfähige und
verschachtelte Bausteine), eigene Canvas-Ansicht für den Unterplan,
Runner-End-to-End-Tests, JSON-Pointer-Bindungen für Modelleingänge.

## Siehe auch

- [OCR-Pipeline](./ocr-pipeline.md)
- [Modelleingaben im Baustein](./modelleingaben-im-baustein.md)
- [Aufgabe](../index/aufgabe.md)
