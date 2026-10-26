# Transformation `tensor.nonMaximumSuppression`

> Liest Erkennungen aus den Zeilen eines Tensors und unterdrückt überlappende Boxen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `detections`

Mit `classScores` gilt die beste Klasse (`classIndex`) und je Klasse wird unterdrückt; mit `objectnessIndex` wird deren Wert mit dem Score multipliziert (YOLOv5-Stil). Ergebnis `{index, score, box, classIndex?}`, `box` immer als Ecken.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `box` | Objekt mit `left`, `top`, `right`, `bottom` oder Objekt mit `centerX`, `centerY`, `width`, `height` | ja | – |
| `scoreIndex` | ganze Zahl ≥ 0 | nein | – |
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

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
