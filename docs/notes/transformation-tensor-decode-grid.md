# Transformation `tensor.decodeGrid`

> Dekodiert Rohboxen ankerfreier Detektoren aus Rasterzellen in Modellpixel.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Die Zeilen folgen den Strides in Reihenfolge, je Stride zeilenweise über das Raster `(height/stride) × (width/stride)`. Je Zeile: `centerX = (x + spalte) × stride`, `centerY = (y + zeile) × stride`, Breite und Höhe `exp(w) × stride` (oder linear). Andere Spalten (Objectness, Klassen) bleiben unverändert; danach liest `tensor.nonMaximumSuppression`.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `strides` | Liste aus ganze Zahl ≥ 1 | ja | – |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |
| `box` | Objekt mit `centerX`, `centerY`, `width`, `height` | ja | – |
| `sizeEncoding` | `exp` oder `linear` | nein | `"exp"` |

## Beispiel

YOLOX-Export ohne Dekodierung; danach `tensor.nonMaximumSuppression` mit `objectnessIndex: 4` und `classScores: {start: 5}`.

```json
{"type": "tensor.decodeGrid", "parameters": {"strides": [8, 16, 32], "width": 640, "height": 640, "box": {"centerX": 0, "centerY": 1, "width": 2, "height": 3}}}
```

## Fachliche Tests

- [`test_detection_decoding.py`](../../local-runtime/python/tests/test_detection_decoding.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
