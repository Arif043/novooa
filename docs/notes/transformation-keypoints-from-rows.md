# Transformation `keypoints.fromRows`

> Liest Keypoints aus Zeilen eines Tensors, eine Zeile je Punkt.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `keypoints`

`x`, `y` und optional `score` nennen die Spalten; `scale` rechnet normierte Koordinaten (0…1) in Modellpixel um. Führende Batch-Achsen der Größe 1 entfallen (`[1, 1, 17, 3]`).

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `x` | ganze Zahl ≥ 0 | ja | – |
| `y` | ganze Zahl ≥ 0 | ja | – |
| `score` | ganze Zahl ≥ 0 | nein | – |
| `scale` | Objekt mit `x`, `y` | nein | – |

## Beispiel

MoveNet SinglePose: `[1, 1, 17, 3]` mit (y, x, score) normiert auf 192 × 192.

```json
{"type": "keypoints.fromRows", "parameters": {"x": 1, "y": 0, "score": 2, "scale": {"x": 192, "y": 192}}}
```

## Fachliche Tests

- [`test_keypoints.py`](../../local-runtime/python/tests/test_keypoints.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
