# Transformation `image.decode`

> Dekodiert eine Bilddatei und setzt den Farbraum (`rgb`, `rgba` oder `grayscale`).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `colorSpace` | `rgb` oder `rgba` oder `grayscale` | ja | – |

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "image.decode", "parameters": {"colorSpace": "rgb"}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
