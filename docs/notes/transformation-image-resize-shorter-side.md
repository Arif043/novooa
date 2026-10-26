# Transformation `image.resizeShorterSide`

> Skaliert die kürzere Seite auf `size`, das Seitenverhältnis bleibt.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `size` | ganze Zahl ≥ 1 | ja | – |

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)
- [`test_validation_workers.py`](../../local-runtime/python/tests/test_validation_workers.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
