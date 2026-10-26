# PP-OCRv6 Small Texterkennung (`pp-ocr-v6-text-detector-small`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** geprüft

## Steckbrief

ID `pp-ocr-v6-text-detector-small`, Version `rapidocr-3.9.2`, Aufgabe
`optical-character-recognition`, sprachunabhängig, Tags `invoices`,
`receipts`, `lightweight`. Findet Textzeilen in Dokumenten und Belegen für den
[Recognizer](../recognizer/JOURNAL.md).

## Herkunft

- Quelle: [RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml),
  Version 3.9.2, Datei `PP-OCRv6_det_small` → `model.onnx`.
- SHA-256 `model.onnx`: `090f04abcd9d9a7498bc4ebf677e4cb9bdce1fe4197ddb7e529f1ef44e1ff94f`
  (9 929 594 Bytes).

## Lizenz

- Gewichte und Code: Apache 2.0 (PaddleOCR, Konvertierung durch RapidOCR).
- Bewertung: geklärt für Gewichte und Code; Namensnennung bei Weitergabe beachten.

## Dokumentation

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR),
  [RapidOCR](https://github.com/RapidAI/RapidOCR); ein technischer Bericht zu
  PP-OCRv6 ist hier noch nicht verlinkt (offen).

## Vertrag

- Eingang `x` (Bild): `image.decode` → `image.padToMultiple` (32) →
  `tensor.channelOrder` → `tensor.layout` → `tensor.normalize` (ImageNet-Werte).
- Ausgang `fetch_name_0` → `mask.textRegions` (Schwelle 0,3, Score ≥ 0,5,
  Dilatation 3 × 1, Rand 1) → `geometry.mergeRows` (Überlappung 0,5) →
  Workflow-Wert `regions` in Originalkoordinaten.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf erfolgreich.
- Fachlicher Referenztest gegen RapidOCR: offen.

## Grenzen

- `mask.textRegions` mit Dilatation nähert die DB-Nachverarbeitung (Unclip) an,
  ist aber nicht identisch.
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Trockenlauf erfolgreich.
