# Modellkatalog ohne `scope` und `runtime` (0015)

> Im Modellkatalog bedeutet `team_id = NULL` Systemmodell und eine gesetzte Team-ID Teammodell.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Die Spalten `scope` und `runtime` entfallen; der SQLite-Adapter ergänzt die
  Runtime `onnx` aus dem Fachmodell.
- Schreibzugriffe validieren über den gemeinsamen Katalog-Codec, bevor Daten
  sich ändern.
- Sichtbarkeit und Löschen von Teammodellen filtern direkt über `team_id`.
- Teamzuordnung, JSON-Aggregate, Zeitpunkte und Löschkaskaden bleiben.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [ML-Modelle](../features/ml-modelle.md)
