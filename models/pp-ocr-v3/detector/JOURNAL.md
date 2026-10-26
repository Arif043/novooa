# PP-OCRv3 Texterkennung (`pp-ocr-v3-text-detector`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** geprüft

## Steckbrief

ID `pp-ocr-v3-text-detector`, Version `rapidocr-3.9.2`, Aufgabe
`optical-character-recognition`, sprachunabhängig, Tags `invoices`.
Findet Textbereiche in Dokumentbildern; die Erkennung je Bereich übernimmt
der [Recognizer](../recognizer/JOURNAL.md) in einer „Für jedes Element“-Schleife.

## Herkunft

- Quelle: [RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml),
  Version 3.9.2, Datei `multi_PP-OCRv3_det_mobile.onnx` → `model.onnx`.
- SHA-256 `model.onnx`: `5582933662898cd2b4c2eae8a7e5e4fbdff84773711f29db00a1cbd185059001`
  (2 421 639 Bytes).

## Lizenz

- Gewichte und Code: Apache 2.0 (PaddleOCR, Konvertierung durch RapidOCR).
- Trainingsdaten: laut PaddleOCR eigene und öffentliche Datensätze; nicht
  einzeln geprüft.
- Bewertung: geklärt für Gewichte und Code; Namensnennung (Apache 2.0, NOTICE)
  bei Weitergabe beachten.

## Dokumentation

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR), technischer Bericht
  [PP-OCRv3 (arXiv 2206.03001)](https://arxiv.org/abs/2206.03001).
- Referenz der Vor- und Nachverarbeitung: RapidOCR `ch_ppocr_det` (DB-Nachverarbeitung).

## Vertrag

- Eingang `x` (Bild, `[dynamic, 3, dynamic, dynamic]`): `image.decode` →
  `image.padToMultiple` (32) → `tensor.channelOrder` (BGR) → `tensor.layout` →
  `tensor.normalize` (ImageNet-Werte in 0…255).
- Ausgang `sigmoid_0.tmp_0` → `tensor.threshold` (0,3) →
  `mask.connectedComponents` (≥ 64 Pixel) → Workflow-Wert `regions`.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf
  `models:install-local --dry-run` erfolgreich.
- Fachlicher Referenztest gegen RapidOCR: offen.

## Grenzen

- Ohne „Unclip“ der DB-Nachverarbeitung: Regionen sind knapper als bei
  RapidOCR; Ränder von Buchstaben können fehlen.
- Titel und Beschreibung sind deutsch; laut [Mehrsprachige Manifeste](../../../docs/notes/mehrsprachige-manifeste.md)
  sollten sie englisch sein, mit deutscher Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags aus dem Vokabular ergänzt; Journal nachgetragen;
  Trockenlauf erfolgreich.
