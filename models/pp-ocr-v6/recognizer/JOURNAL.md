# PP-OCRv6 Small Texterkennung (`pp-ocr-v6-text-recognizer-small`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** geprüft

## Steckbrief

ID `pp-ocr-v6-text-recognizer-small`, Version `rapidocr-3.9.2`, Aufgabe
`optical-character-recognition`, sprachunabhängig, Tags `invoices`,
`receipts`, `lightweight`. Liest den Text einer Region, die der
[Detektor](../detector/JOURNAL.md) gefunden hat.

## Herkunft

- Quelle: [RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml),
  Version 3.9.2, Datei `PP-OCRv6_rec_small` → `model.onnx`.
- SHA-256 `model.onnx`: `6f327246b50388f3c176ae304bd95767ea6dc0c9ae92153ef8cbe210b3c14884`
  (21 234 383 Bytes).
- Zeichenliste `ppocrv6_dict.txt`, SHA-256
  `b5f2bfe2bdd9448429e3e82b51c789775d9b42f2403d082b00662eb77e401c5d`; im Manifest
  als `labels` von `sequence.ctcGreedyDecode`.

## Lizenz

- Gewichte, Code und Zeichenliste: Apache 2.0 (PaddleOCR, Konvertierung durch RapidOCR).
- Bewertung: geklärt für Gewichte und Code; Namensnennung bei Weitergabe beachten.

## Dokumentation

- [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR),
  [RapidOCR](https://github.com/RapidAI/RapidOCR); technischer Bericht zu
  PP-OCRv6 noch nicht verlinkt (offen).

## Vertrag

- Eingang `x` (Bild, `[dynamic, 3, 48, dynamic]`): `image.decode` →
  `image.crop` (Region) → `image.resizeHeightPad` (Höhe 48, Breite Vielfaches
  von 8) → `tensor.channelOrder` → `tensor.layout` → `tensor.normalize` (−1…1).
- Ausgang `fetch_name_0` → `sequence.ctcGreedyDecode` (18 710 Labels, Blank 0)
  → Workflow-Wert `recognition`.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf erfolgreich.
- Fachlicher Referenztest gegen RapidOCR: offen.

## Grenzen

- Ohne Einschränkung des Alphabets: Verwechslungen mit ähnlichen Zeichen anderer
  Schriften sind möglich (vgl. `allowedCharacters` bei PP-OCRv5 Server).
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Trockenlauf erfolgreich.
