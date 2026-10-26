# Transformation `keypoints.fromHeatmaps`

> Liest je Heatmap den Punkt mit dem höchsten Wert als Keypoint.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `keypoints`

Form `[K, H, W]` oder mit `layout: channelsLast` `[H, W, K]`; `stride` rechnet die Heatmap-Zelle in Modellpixel um (z. B. 4 bei einer Heatmap in Viertelauflösung). Score ist der Höchstwert der Karte.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `stride` | Objekt mit `x`, `y` | nein | – |
| `layout` | `channelsFirst` oder `channelsLast` | nein | `"channelsFirst"` |

## Beispiel

HRNet oder ViTPose mit Heatmaps in Viertelauflösung.

```json
{"type": "keypoints.fromHeatmaps", "parameters": {"stride": {"x": 4, "y": 4}}}
```

## Fachliche Tests

- [`test_keypoints.py`](../../local-runtime/python/tests/test_keypoints.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
