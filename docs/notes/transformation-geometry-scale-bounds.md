# Transformation `geometry.scaleBounds`

> Rechnet eine Regionsliste vom Maskenraster in Bildkoordinaten zurück.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `regions` → `regions`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `scaleX` | Zahl ≥ 0 | ja | – |
| `scaleY` | Zahl ≥ 0 | ja | – |
| `offsetX` | Zahl | nein | `0` |
| `offsetY` | Zahl | nein | `0` |

## Fachliche Tests

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_vision_detection.py`](../../local-runtime/python/tests/test_vision_detection.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
