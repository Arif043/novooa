# Transformation `mask.textRegions`

> Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `regions`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `threshold` | Zahl 0…1 | nein | `0.3` |
| `minimumPixels` | ganze Zahl ≥ 0 | nein | `1` |
| `minimumScore` | Zahl 0…1 | nein | `0` |
| `dilationWidth` | ganze Zahl ≥ 1 | nein | `1` |
| `dilationHeight` | ganze Zahl ≥ 1 | nein | `1` |
| `padding` | ganze Zahl ≥ 0 | nein | `0` |

## Beispiel

Aus `models/pp-ocr-v6/detector/model.json`:

```json
{"type": "mask.textRegions", "parameters": {"threshold": 0.3, "minimumPixels": 8, "minimumScore": 0.5, "dilationWidth": 3, "dilationHeight": 1, "padding": 1}, "result": "detectedRegions"}
```

## Fachliche Tests

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
