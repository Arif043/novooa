# PP-OCRv5 Server Texterkennung (`pp-ocr-v5-server-text-recognizer`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** geprüft

## Steckbrief

ID `pp-ocr-v5-server-text-recognizer`, Version `paddleocr-v5-server-onnx`,
Aufgabe `optical-character-recognition`, Sprache `de` (über das zulässige
Alphabet), Tags `invoices`, `receipts`, `high-quality`. Genauerer, größerer
Recognizer für einzelne Textzeilen.

## Herkunft

- Quelle: [PaddlePaddle/PP-OCRv5_server_rec_onnx](https://huggingface.co/PaddlePaddle/PP-OCRv5_server_rec_onnx),
  Datei `model.onnx`; Zeichenliste aus der mitgelieferten `inference.yml`.
- SHA-256 `model.onnx`: `d9dc333c9c7b042c6dffb8e33d72b6f65c9c1d463d0a3c2f78174fea55e94752`
  (84 503 027 Bytes).
- SHA-256 `inference.yml`: `2c719dba044c4e2228aef8ff92f5f575394d75d24c16de096a33b7cfd902f66d`.

## Lizenz

- Gewichte: Apache 2.0 (Model Card).
- Bewertung: geklärt; Namensnennung bei Weitergabe beachten.

## Dokumentation

- [Model Card](https://huggingface.co/PaddlePaddle/PP-OCRv5_server_rec_onnx),
  [PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR).

## Vertrag

- Eingang `x` (Bild, `[dynamic, 3, 48, dynamic]`): `image.decode` →
  `image.crop` (Region) → `image.resizeHeightPad` (Höhe 48, Breite Vielfaches
  von 8) → `tensor.channelOrder` → `tensor.layout` → `tensor.normalize` (−1…1).
- Ausgang `fetch_name_0` → `sequence.ctcGreedyDecode` (18 385 Labels,
  `allowedCharacters`: deutsche Buchstaben, Ziffern, Belegzeichen) →
  Workflow-Wert `recognition`.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf erfolgreich.
- Fachlicher Referenztest gegen PaddleOCR: offen.

## Grenzen

- `allowedCharacters` schließt alle anderen Schriften aus; für nichtdeutsche
  Belege ein eigener Eintrag ohne Einschränkung.
- 84 MB: deutlich langsamer auf der CPU als PP-OCRv6 Small.
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task`, Sprache und Tags ergänzt; Journal nachgetragen;
  Trockenlauf erfolgreich.
