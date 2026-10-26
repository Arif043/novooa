# Transformation `mask.connectedComponents`

> Liefert Regionen als `{bounds, pixelCount}`; `bounds` enthält `left`, `top`, `width`, `height`.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `regions`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `minimumPixels` | ganze Zahl ≥ 0 | nein | `1` |

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "mask.connectedComponents", "parameters": {"minimumPixels": 64}, "result": "regions"}
```

## Fachliche Tests

- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)
- [`test_vision_detection.py`](../../local-runtime/python/tests/test_vision_detection.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
