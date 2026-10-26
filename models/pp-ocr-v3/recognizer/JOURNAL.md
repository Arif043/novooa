# PP-OCRv3 Latin Texterkennung (`pp-ocr-v3-latin-text-recognizer`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** geprüft

## Steckbrief

ID `pp-ocr-v3-latin-text-recognizer`, Version `rapidocr-3.9.2`, Aufgabe
`optical-character-recognition`, sprachunabhängig (lateinische Schrift), Tags
`invoices`, `latin-script`. Liest den Text einer Region, die der
[Detektor](../detector/JOURNAL.md) gefunden hat.

## Herkunft

- Quelle: [RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml),
  Version 3.9.2, Datei `latin_PP-OCRv3_rec_mobile.onnx` → `model.onnx`.
- SHA-256 `model.onnx`: `e9d7a33667e8aaa702862975186adf2012e3f390cc0f9422865957125f8071cf`
  (8 978 191 Bytes).
- Zeichenliste: [PaddleOCR `latin_dict.txt` (release/2.6)](https://github.com/PaddlePaddle/PaddleOCR/blob/release/2.6/ppocr/utils/dict/latin_dict.txt)
  → `latin_dict.txt`, SHA-256 `8e6d4e3629788c35c31f7e530287d6147b549bb7a265bd6708bb281134429e2c`;
  im Manifest als `labels` von `sequence.ctcGreedyDecode`.

## Lizenz

- Gewichte, Code und Zeichenliste: Apache 2.0 (PaddleOCR, Konvertierung durch RapidOCR).
- Bewertung: geklärt für Gewichte und Code; Namensnennung bei Weitergabe beachten.

## Dokumentation

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR), technischer Bericht
  [PP-OCRv3 (arXiv 2206.03001)](https://arxiv.org/abs/2206.03001).
- Referenz der Vor- und Nachverarbeitung: RapidOCR `ch_ppocr_rec` (CTC-Dekodierung).

## Vertrag

- Eingang `x` (Bild): `image.decode` → `image.crop` (Region aus
  `$iteration.value.bounds`) → `image.resizePad` (320 × 48, links oben) →
  `tensor.channelOrder` (BGR) → `tensor.layout` → `tensor.normalize` (auf −1…1).
- Ausgang `softmax_2.tmp_0` → `sequence.ctcGreedyDecode` (187 Labels, Blank 0)
  → Workflow-Wert `recognition` mit Text und Konfidenz.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf erfolgreich.
- Fachlicher Referenztest gegen RapidOCR: offen.

## Grenzen

- Feste Breite 320: lange Zeilen werden gestaucht; RapidOCR skaliert die Breite
  dynamisch (siehe PP-OCRv6 mit `image.resizeHeightPad`).
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Trockenlauf erfolgreich.
