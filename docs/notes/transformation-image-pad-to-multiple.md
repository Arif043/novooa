# Transformation `image.padToMultiple`

> Füllt rechts und unten bis zu einem Vielfachen auf; Bildkoordinaten bleiben erhalten.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `multiple` | ganze Zahl ≥ 1 | ja | – |
| `background` | ganze Zahl 0…255 | nein | `0` |
| `colorSpace` | `rgb` oder `rgba` oder `grayscale` | nein | – |

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "image.padToMultiple", "parameters": {"multiple": 32, "background": 0}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
