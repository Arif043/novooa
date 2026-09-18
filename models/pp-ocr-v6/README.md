# PP-OCRv6 Small-Artefakte

Dieses Verzeichnis enthält die ONNX-Artefakte `PP-OCRv6_det_small` und
`PP-OCRv6_rec_small` aus dem
[RapidOCR-Modellkatalog](https://github.com/RapidAI/RapidOCR/blob/main/python/rapidocr/default_models.yaml).

Die Manifeste halten Detektion und Erkennung als getrennte, allgemein
kombinierbare Modellbausteine. Der Detector führt seine Wahrscheinlichkeitsmaske über `mask.textRegions` in
Textzeilen in der Originalbildauflösung über. Der Recognizer verwendet `image.resizeHeightPad`
mit dynamischer Breite, damit flache oder lange Textregionen auf die erwartete
Modellhöhe normalisiert werden.

## Prüfsummen

| Artefakt | SHA-256 |
| --- | --- |
| `detector/model.onnx` | `090f04abcd9d9a7498bc4ebf677e4cb9bdce1fe4197ddb7e529f1ef44e1ff94f` |
| `recognizer/model.onnx` | `6f327246b50388f3c176ae304bd95767ea6dc0c9ae92153ef8cbe210b3c14884` |
