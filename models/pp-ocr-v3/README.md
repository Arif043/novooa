# PP-OCRv3-Artefakte

Dieses Verzeichnis enthält zwei ONNX-Artefakte aus RapidOCR 3.9.2 für die lokale
Dokumentverarbeitung:

- `detector/model.onnx`: `multi_PP-OCRv3_det_mobile.onnx`
- `recognizer/model.onnx`: `latin_PP-OCRv3_rec_mobile.onnx`

Die Artefakte stammen aus dem [RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml).
Die Latin-Zeichenliste wurde aus
[PaddleOCR](https://github.com/PaddlePaddle/PaddleOCR/blob/release/2.6/ppocr/utils/dict/latin_dict.txt)
übernommen. RapidOCR beschreibt die abgeleiteten ONNX-Artefakte als Apache-2.0;
bei einer Weitergabe sind die Bedingungen der jeweiligen Upstream-Projekte zu
beachten.

## Prüfsummen

| Artefakt | SHA-256 |
| --- | --- |
| `detector/model.onnx` | `5582933662898cd2b4c2eae8a7e5e4fbdff84773711f29db00a1cbd185059001` |
| `recognizer/model.onnx` | `e9d7a33667e8aaa702862975186adf2012e3f390cc0f9422865957125f8071cf` |

Die Manifeste modellieren Erkennung und Texterkennung getrennt. Die
Orchestrierung erfolgt in einer Aufgabe über einen `forEach`-Baustein.
