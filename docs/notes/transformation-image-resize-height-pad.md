# Transformation `image.resizeHeightPad`

> Skaliert ein Bild auf die Zielhöhe und füllt die Breite auf, schneidet sie ab oder lässt sie dynamisch.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

Mit `width` wird bis zur festen Breite aufgefüllt bzw. abgeschnitten; ohne `width` bleibt die Breite dynamisch und kann auf ein Vielfaches aufgefüllt werden.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `height` | ganze Zahl ≥ 1 | ja | – |
| `width` | ganze Zahl ≥ 1 | nein | – |
| `widthMultiple` | ganze Zahl ≥ 1 | nein | – |
| `alignment` | `topLeft` oder `center` | nein | `"topLeft"` |
| `background` | ganze Zahl 0…255 | nein | `0` |
| `colorSpace` | `rgb` oder `rgba` oder `grayscale` | nein | – |

## Beispiel

Aus `models/pp-ocr-v5/server-recognizer/model.json`:

```json
{"type": "image.resizeHeightPad", "parameters": {"height": 48, "widthMultiple": 8, "alignment": "topLeft", "background": 0}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_image_steps.py`](../../local-runtime/python/tests/test_image_steps.py)
- [`test_image_resize_height_pad.py`](../../local-runtime/python/tests/test_image_resize_height_pad.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
