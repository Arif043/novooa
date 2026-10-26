# Transformation `tensor.nonMaximumSuppression`

> Liest Erkennungen aus den Zeilen eines Tensors und unterdrückt überlappende Boxen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `detections`

Mit `classScores` gilt die beste Klasse (`classIndex`) und je Klasse wird unterdrückt; mit `objectnessIndex` wird deren Wert mit dem Score multipliziert (YOLOv5-Stil). `classColumn` liest die Klasse aus einer Spalte (Zeilen wie `[klasse, score, x1, y1, x2, y2]`), `scoreActivation` macht Logits zu Wahrscheinlichkeiten, `suppress: false` lässt die Unterdrückung aus — für Exporte mit eingebauter NMS und DETR-Modelle. Ergebnis `{index, score, box, classIndex?}`, `box` immer als Ecken.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `box` | Objekt mit `left`, `top`, `right`, `bottom` oder Objekt mit `centerX`, `centerY`, `width`, `height` | ja | – |
| `scoreIndex` | ganze Zahl ≥ 0 | nein | – |
| `classColumn` | ganze Zahl ≥ 0 (nur mit `scoreIndex`) | nein | – |
| `scoreActivation` | `none` oder `sigmoid` oder `softmax` (`softmax` nur mit `classScores`) | nein | `"none"` |
| `suppress` | Wahrheitswert | nein | `true` |
| `classScores` | Objekt mit `start`, `end` | nein | – |
| `objectnessIndex` | ganze Zahl ≥ 0 | nein | – |
| `classAware` | Wahrheitswert | nein | `true` |
| `boxScale` | Objekt mit `x`, `y` | nein | – |
| `scoreThreshold` | Zahl | nein | – |
| `iouThreshold` | Zahl 0…1 | nein | `0.5` |
| `maxDetections` | ganze Zahl ≥ 1 | nein | – |

Hinweis: `box` (Spalten als Ecken `left/top/right/bottom` oder Mittelpunkt `centerX/centerY/width/height`), `scoreIndex` oder `classScores` (`{start, end?}`), optional `objectnessIndex`, `classAware` (Standard `true`), `boxScale` (`{x, y}`, z. B. für normierte 0…1-Koordinaten), `scoreThreshold`, `iouThreshold`, `maxDetections`

## Fachliche Tests

- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)
- [`test_vision_detection.py`](../../local-runtime/python/tests/test_vision_detection.py)
- [`test_detector_formats.py`](../../local-runtime/python/tests/test_detector_formats.py)
- [`test_resource_lookup.py`](../../local-runtime/python/tests/test_resource_lookup.py)
- [`test_detection_decoding.py`](../../local-runtime/python/tests/test_detection_decoding.py)
- [`test_output_references.py`](../../local-runtime/python/tests/test_output_references.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
