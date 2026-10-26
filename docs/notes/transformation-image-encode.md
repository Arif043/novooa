# Transformation `image.encode`

> Kodiert einen Tensor als Bilddatei (Werte auf 0…255 begrenzt); mit `palette` werden Klassenindizes eingefärbt.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `imageFile`

Workflow-Typ `image`.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `format` | `png` oder `jpeg` | nein | `"png"` |
| `fileName` | Text | nein | – |
| `layout` | `channelsFirst` oder `channelsLast` | nein | `"channelsLast"` |
| `palette` | Liste aus Liste aus ganze Zahl 0…255 | nein | – |

Hinweis: optional `format` (`png`, `jpeg`), `fileName`, `layout` (Standard `channelsLast`), `palette` (Liste von `[r, g, b]`)

## Fachliche Tests

- [`test_image_outputs.py`](../../local-runtime/python/tests/test_image_outputs.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
- [Typebenen eines Modellvertrags](./modell-typebenen.md)
