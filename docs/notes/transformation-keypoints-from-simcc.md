# Transformation `keypoints.fromSimcc`

> Dekodiert Keypoints aus SimCC-Verteilungen je Achse zweier Modellausgänge.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `keypoints`

Der Ausgang liefert die x-Verteilungen `[K, Wx]`, der Rohausgang `yOutput` die y-Verteilungen `[K, Hy]`. Koordinate = Index des Maximums / `splitRatio`; Score ist das kleinere der beiden Maxima, wie in der Referenzimplementierung von MMPose.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `yOutput` | Name eines Modellausgangs | ja | – |
| `splitRatio` | Zahl ≥ 0 | nein | `2.0` |

## Beispiel

Ausgang `simcc_x` von RTMPose.

```json
{"type": "keypoints.fromSimcc", "parameters": {"yOutput": "simcc_y", "splitRatio": 2.0}}
```

## Fachliche Tests

- [`test_keypoints.py`](../../local-runtime/python/tests/test_keypoints.py)
- [`test_output_references.py`](../../local-runtime/python/tests/test_output_references.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Bildgeometrie und Originalkoordinaten](./bildgeometrie-originalkoordinaten.md)
