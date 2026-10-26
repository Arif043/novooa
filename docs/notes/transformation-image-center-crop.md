# Transformation `image.centerCrop`

> Schneidet einen Ausschnitt aus der Bildmitte; größer als das Bild ist ein Fehler.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

Mit `image.resizeShorterSide` die übliche Vorverarbeitung vieler Bildmodelle.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
