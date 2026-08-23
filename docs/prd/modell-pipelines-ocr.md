# Allgemeine Modell-Pipelines und OCR-Nachweis

## Ziel

Aufgaben verarbeiten Modellantworten als fachliche JSON-Werte. Der Baustein
`Für jedes Element` führt einen eingebetteten Arbeitsplan für jedes Element
eines JSON-Arrays in Eingabereihenfolge aus.

## Akzeptanzkriterien

- Kanten bestimmen ausschließlich Reihenfolge und Abhängigkeiten.
- `Für jedes Element` liest ein Array über RFC-6901-JSON-Pointer und aggregiert
  die primären Ergebnisse als JSON-Array.
- Jede Iteration erhält ausschließlich ihr aktuelles Element als `value`.
- Unterpläne laufen seriell und brechen bei einem Fehler mit dem Elementindex ab.
- Pausierende und verschachtelte `Für jedes Element`-Bausteine sind im
  Unterplan nicht zulässig.

## Nicht enthalten

Ein produktiver PaddleOCR-Nachweis benötigt kuratierte ONNX-Dateien,
Zeichenliste und einen datenschutzgeprüften Beleg. Diese Artefakte sind noch
nicht im Repository vorhanden und werden nicht durch Platzhalter ersetzt.
