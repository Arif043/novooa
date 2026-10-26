# Transformation `geometry.mergeRows`

> Fasst horizontale Textregionen mit ausreichender vertikaler Überlappung zu einer Zeile zusammen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `regions` → `regions`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `minimumVerticalOverlap` | Zahl 0…1 | nein | `0.5` |

## Beispiel

Aus `models/pp-ocr-v6/detector/model.json`:

```json
{"type": "geometry.mergeRows", "parameters": {"minimumVerticalOverlap": 0.5}, "result": "regions"}
```

## Fachliche Tests

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_vision_detection.py`](../../local-runtime/python/tests/test_vision_detection.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
