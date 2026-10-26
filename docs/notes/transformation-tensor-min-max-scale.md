# Transformation `tensor.minMaxScale`

> Skaliert Werte linear vom eigenen Minimum und Maximum auf einen Zielbereich.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Für Ausgaben ohne festen Wertebereich, etwa relative Tiefen- oder Saliency-Karten, die als Bild gespeichert werden (`maximum: 255`). Ein konstanter Tensor ergibt überall `minimum`.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `minimum` | Zahl | nein | `0` |
| `maximum` | Zahl | nein | `1` |

## Beispiel

Relative Tiefenkarte (Depth Anything) vor `image.encode`.

```json
{"type": "tensor.minMaxScale", "parameters": {"maximum": 255}}
```

## Fachliche Tests

- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
