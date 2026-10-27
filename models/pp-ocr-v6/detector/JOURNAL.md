# PP-OCRv6 Small Texterkennung (`pp-ocr-v6-text-detector-small`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** veröffentlicht

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

Nach RapidOCR 3.10 (`Det`-Konfiguration für PP-OCRv6):

- Eingang `x` (Bild): `image.decode` → `image.resizeWithin` (kürzere Seite
  ≥ 736, längere ≤ 2000) → `image.padToMultiple` (32) → `tensor.channelOrder`
  (BGR) → `tensor.layout` → `tensor.normalize` (Mittelwert und
  Standardabweichung 127,5, also −1…1).
- Ausgang `fetch_name_0` → `mask.textRegions` (Schwelle 0,3, Score ≥ 0,5,
  Dilatation 2 × 2, `unclipRatio` 1,6) → `geometry.mergeRows` (Überlappung 0,5)
  → `geometry.toSource` → Workflow-Wert `regions` in Originalkoordinaten.
- Abweichungen: RapidOCR skaliert auf Vielfache von 32 statt aufzufüllen und
  arbeitet mit gedrehten Rechtecken; wir mit achsenparallelen Boxen.

## Prüfung

- 2026-10-26: Vertragsprüfung, ONNX-Prüfung und Trockenlauf erfolgreich.
- 2026-10-27: fachlicher Referenztest bestanden
  ([`test_reference_pp_ocr_v6.py`](../../../local-runtime/python/tests/test_reference_pp_ocr_v6.py)):
  synthetischer deutscher Beleg, 8 von 8 Zeilen wie RapidOCR (Boxen-IoU ≥ 0,7),
  Text ohne Leerzeichen identisch mit RapidOCR und dem wahren Text.

## Grenzen

- Achsenparallele Boxen: schräg fotografierte Belege ergeben größere, sich
  überlappende Regionen als die gedrehten Rechtecke von RapidOCR.
- Der Referenzfall ist ein sauberer, gerade gerenderter Beleg; Fotos mit
  Schatten oder Knicken sind noch nicht geprüft.
- Titel und Beschreibung sind deutsch statt englisch mit Übersetzung (offen).

## Verlauf

- Vor 2026-10-26 — Manifest und Artefakt angelegt (nicht dokumentiert).
- 2026-10-26 — `task` und Tags ergänzt; Journal nachgetragen; Trockenlauf erfolgreich.
- 2026-10-27 — Referenztest: Regionen waren halb so hoch wie bei RapidOCR, der
  Recognizer las 6 von 8 Zeilen falsch. Ursache fehlendes Unclip; Vertrag an
  RapidOCR angeglichen (`unclipRatio`, Normalisierung, `image.resizeWithin`,
  `geometry.toSource`). Referenztest bestanden.
- 2026-10-27 — Veröffentlicht als `pp-ocr-v6-text-detector-small@rapidocr-3.9.2` (Projekt
  `syscat-90bff`, Garage-Bucket `web-novooa-models.arif-it.de`):
  `npm --prefix functions run models:publish -- --project syscat-90bff --manifest <repo>/models/pp-ocr-v6/detector/model.json --artifact <repo>/models/pp-ocr-v6/detector/model.onnx`.
  Geprüft: Katalogeintrag in Firestore, anonymer Abruf über den
  Website-Endpunkt (9 929 594 Bytes, SHA-256 wie im Eintrag).
