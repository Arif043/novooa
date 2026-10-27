# PP-OCRv6 Small Texterkennung (`pp-ocr-v6-text-recognizer-small`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** veröffentlicht

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
- 2026-10-27: fachlicher Referenztest zusammen mit dem Detektor bestanden
  ([`test_reference_pp_ocr_v6.py`](../../../local-runtime/python/tests/test_reference_pp_ocr_v6.py)):
  Text aller 8 Zeilen ohne Leerzeichen identisch mit RapidOCR und dem wahren Text.

## Grenzen

- Leerzeichen zwischen eng stehenden Wörtern setzt das Modell nicht immer
  („26.10.202614:32“), auch bei RapidOCR.
- Ohne Einschränkung des Alphabets: Verwechslungen mit ähnlichen Zeichen anderer
  Schriften sind möglich (vgl. `allowedCharacters` bei PP-OCRv5 Server).
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Trockenlauf erfolgreich.
- 2026-10-27 — Referenztest mit dem Detektor bestanden; Vertrag unverändert.
- 2026-10-27 — Veröffentlicht als `pp-ocr-v6-text-recognizer-small@rapidocr-3.9.2` (Projekt
  `syscat-90bff`, Garage-Bucket `web-novooa-models.arif-it.de`):
  `npm --prefix functions run models:publish -- --project syscat-90bff --manifest <repo>/models/pp-ocr-v6/recognizer/model.json --artifact <repo>/models/pp-ocr-v6/recognizer/model.onnx`.
  Geprüft: Katalogeintrag in Firestore, anonymer Abruf über den
  Website-Endpunkt (21 234 383 Bytes, SHA-256 wie im Eintrag).
