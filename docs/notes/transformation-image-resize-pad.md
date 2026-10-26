# Transformation `image.resizePad`

> Skaliert ein Bild unter Erhalt des Seitenverhältnisses und füllt bis zur Zielgröße auf (Letterbox).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `width` | ganze Zahl ≥ 1 | ja | – |
| `height` | ganze Zahl ≥ 1 | ja | – |
| `alignment` | `topLeft` oder `center` | nein | `"topLeft"` |
| `background` | ganze Zahl 0…255 | nein | `0` |
| `colorSpace` | `rgb` oder `rgba` oder `grayscale` | nein | – |

## Beispiel

Aus `models/pp-ocr-v3/recognizer/model.json`:

```json
{"type": "image.resizePad", "parameters": {"width": 320, "height": 48, "alignment": "topLeft", "background": 0}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
