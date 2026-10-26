# Transformation `image.tiles`

> Zerlegt ein Bild in überlappende Kacheln und rechnet sie als Batch.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `image` → `tensor`

Für Modelle mit fester oder begrenzter Eingabegröße (Hochskalieren, Segmentierung großer Bilder). Benachbarte Kacheln überlappen um `overlap` Pixel; der Rand wird mit den Randpixeln aufgefüllt. Das Raster reist in den Metadaten, `tensor.untile` setzt das Ergebnis zusammen.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `size` | ganze Zahl ≥ 1 | ja | – |
| `overlap` | ganze Zahl ≥ 0 | nein | `0` |

## Beispiel

Real-ESRGAN mit dynamischer Batch-Achse; danach `tensor.scale` (1/255) und `tensor.layout`.

```json
{"type": "image.tiles", "parameters": {"size": 128, "overlap": 16}}
```

## Fachliche Tests

- [`test_tiles_and_frames.py`](../../local-runtime/python/tests/test_tiles_and_frames.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Transformation tensor.untile](./transformation-tensor-untile.md)
