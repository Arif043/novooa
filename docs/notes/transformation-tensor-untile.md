# Transformation `tensor.untile`

> Setzt die Kacheln eines Batches nach dem Raster von `image.tiles` zu einem Bild zusammen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Das Raster kommt aus den Metadaten des Eingangs `input`. `scale` ist der Vergrößerungsfaktor des Modells (z. B. 4 bei Real-ESRGAN, 1 bei Segmentierung). Jede Kachel steuert nur ihren mittleren Teil bei — überlappende Ränder werden halbiert —, Auffüllung wird abgeschnitten. Ergebnis `[H × scale, W × scale, C]`; mit `layout: channelsFirst` werden `[N, C, h, w]` gelesen.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `input` | Text | ja | – |
| `scale` | Zahl ≥ 0 | nein | `1` |
| `layout` | `channelsFirst` oder `channelsLast` | nein | `"channelsLast"` |

## Beispiel

Real-ESRGAN ×4 auf Kacheln; danach `tensor.scale` (×255) und `image.encode`.

```json
{"type": "tensor.untile", "parameters": {"input": "image", "scale": 4, "layout": "channelsFirst"}}
```

## Fachliche Tests

- [`test_tiles_and_frames.py`](../../local-runtime/python/tests/test_tiles_and_frames.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Transformation image.tiles](./transformation-image-tiles.md)
