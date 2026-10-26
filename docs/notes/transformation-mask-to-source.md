# Transformation `mask.toSource`

> Bildet eine Maske oder Karte `[H, W]`, `[C, H, W]` bzw. `[H, W, C]` per Nearest-Neighbour auf die Originalgröße ab; Rand des Modellbildes wird zu `fill`.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `input` | Text | ja | – |
| `layout` | `channelsFirst` oder `channelsLast` | nein | `"channelsFirst"` |
| `fill` | Zahl | nein | `0` |

Hinweis: `input`, optional `layout` (`channelsFirst`, `channelsLast`), `fill` (Standard `0`)

## Fachliche Tests

- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
