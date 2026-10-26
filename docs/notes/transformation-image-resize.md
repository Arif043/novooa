# Transformation `image.resize`

> Skaliert ein Bild auf feste Breite und Höhe (LANCZOS); das Seitenverhältnis kann sich dabei ändern.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |
| `colorSpace` | `rgb` oder `rgba` oder `grayscale` | nein | – |

## Beispiel

Aus `models/squeezenet-1.1/model.json`:

```json
{"type": "image.resize", "parameters": {"width": 224, "height": 224}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)
- [`test_validation_workers.py`](../../local-runtime/python/tests/test_validation_workers.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
