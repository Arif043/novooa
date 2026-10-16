# Modellbündel

> Ein Modellbündel sind alle Dateien einer Modellversion; sein Schlüssel ist der SHA-256 über die sortierten Zeilen `pfad:prüfsumme`.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Inhalt: `model.onnx`, Gewichte unter ihrem Namen, `resources/<name>`.
`modelBundleFor` (Node) und `bundle_key` (Python) rechnen den Schlüssel gleich;
beide Testsuiten prüfen denselben Wert.

- **Globale Modelle** (Katalog, Systemmodelle) tragen ihren `storePath`. Der
  ML-Dienst lädt sie einmal aus `MODEL_STORE_URL` nach
  `<ML_DATA_DIR>/bundles/global`; alle Mandanten teilen Bündel und Sitzung.
- **Eigene Modelle**: Fehlen Dateien, antwortet der Dienst
  `409 bundle_files_missing` mit den Pfaden; die Runtime streamt genau diese
  und lädt erneut. Ablage im Teamspeicher des Mandanten
  (`<ML_DATA_DIR>/bundles/teams/<registrierung>`).
- Jede Datei wird beim Schreiben gegen Größe und SHA-256 geprüft; ein Bündel
  erscheint erst vollständig (atomares Umbenennen).
- Ressourcen werden beim Laden einer Session aus dem geprüften Bündel
  gelesen; Transformationen bekommen nur lesenden Zugriff auf deren Bytes,
  nie einen Pfad.

Code: `local-runtime/python/novooa_bundles` (nur Standardbibliothek).

## Siehe auch

- [Schnittstelle des ML-Dienstes](./ml-dienst-schnittstelle.md)
- [ML-Mandanten](./ml-mandanten.md)
- [Globaler Modellspeicher](./globaler-modellspeicher.md)
