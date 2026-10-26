# Transformation `image.perspectiveCrop`

> Richtet ein Viereck perspektivisch zu einem Bild aus.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `points` | Liste aus Zahl | ja | – |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
