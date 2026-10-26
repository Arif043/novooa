# Transformation `tensor.decodeAnchors`

> Dekodiert Boxen relativ zu Ankern aus einer Modellressource.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Die Anker stehen als Modellressource `anchors` (JSON-Liste `[[cx, cy, w, h], …]`, eine je Zeile). Je Zeile: `centerX = a_cx + x × v₀ × a_w`, `centerY = a_cy + y × v₀ × a_h`, Breite `a_w × exp(w × v₁)` (oder linear `a_w × w × v₁`) mit `variances = [v₀, v₁]`. Die Boxen haben die Einheit der Anker — normierte Anker brauchen danach `boxScale` in der NMS.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `anchors` | Text | ja | – |
| `box` | Objekt mit `centerX`, `centerY`, `width`, `height` | ja | – |
| `variances` | Liste aus Zahl ≥ 0 | nein | `[0.1, 0.2]` |
| `sizeEncoding` | `exp` oder `linear` | nein | `"exp"` |

## Beispiel

BlazeFace-Gesichtserkennung: Anker als Ressource `anchors`, Rohwerte / 128.

```json
{"type": "tensor.decodeAnchors", "parameters": {"anchors": "anchors", "box": {"centerX": 0, "centerY": 1, "width": 2, "height": 3}, "variances": [0.0078125, 0.0078125], "sizeEncoding": "linear"}}
```

## Fachliche Tests

- [`test_detection_decoding.py`](../../local-runtime/python/tests/test_detection_decoding.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
