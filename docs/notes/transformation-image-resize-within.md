# Transformation `image.resizeWithin`

> Skaliert ein Bild nur, wenn es außerhalb von Grenzen liegt: längere Seite höchstens `maxSide`, kürzere Seite mindestens `minSide`.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `image`

Zuerst wird verkleinert, bis die längere Seite höchstens `maxSide` misst, danach
vergrößert, bis die kürzere Seite mindestens `minSide` misst; das
Seitenverhältnis bleibt, die Geometrie wird für die Rückrechnung aufgezeichnet.
Liegt das Bild innerhalb der Grenzen, bleibt es unverändert. Entspricht
`limit_side_len` von PaddleOCR und RapidOCR — anders als
`image.resizeShorterSide`, das immer auf genau eine Größe skaliert.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `minSide` | ganze Zahl ≥ 1 | nein (mindestens eines von beiden) | – |
| `maxSide` | ganze Zahl ≥ 1 | nein (mindestens eines von beiden) | – |

## Beispiel

Detektor von PP-OCRv6 (wie RapidOCR: kürzere Seite ≥ 736, längere ≤ 2000):

```json
{"type": "image.resizeWithin", "parameters": {"minSide": 736, "maxSide": 2000}}
```

## Fachliche Tests

Ende zu Ende im [Referenztest von PP-OCRv6](../../local-runtime/python/tests/test_reference_pp_ocr_v6.py) gegen RapidOCR; Einzeltests:

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [OCR-Pipeline](./ocr-pipeline.md)
