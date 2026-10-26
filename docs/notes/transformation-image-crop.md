# Transformation `image.crop`

> Schneidet einen achsenparallelen Bildbereich aus.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `left` | ganze Zahl ≥ 0 | ja | – |
| `top` | ganze Zahl ≥ 0 | ja | – |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |

## Beispiel

Aus `models/pp-ocr-v3/recognizer/model.json`:

```json
{"type": "image.crop", "parameters": {"left": "$iteration.value.bounds.left", "top": "$iteration.value.bounds.top", "width": "$iteration.value.bounds.width", "height": "$iteration.value.bounds.height"}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
