# Transformation `geometry.toSource`

> Rechnet `bounds` bzw. `box` mit der Geometrie des Bildeingangs `input` in Koordinaten des Originalbildes zurück; `clip` begrenzt auf das Bild.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `regions` oder `detections` → Wertart der Eingabe

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `input` | Text | ja | – |
| `clip` | Wahrheitswert | nein | `true` |

Hinweis: `input`, optional `clip` (Standard `true`)

## Fachliche Tests

- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)
- [`test_detector_formats.py`](../../local-runtime/python/tests/test_detector_formats.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
