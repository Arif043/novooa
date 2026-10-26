# Transformation `tensor.normalize`

> Normalisiert jeden Farbkanal mit `(wert − mean) / std`.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Die Kanalachse folgt dem Layout aus `tensor.layout`; ein Batch wird je Bild normalisiert.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `mean` | Liste aus Zahl | ja | – |
| `std` | Liste aus Zahl | ja | – |

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "tensor.normalize", "parameters": {"mean": [123.675, 116.28, 103.53], "std": [58.395, 57.12, 57.375]}}
```

## Fachliche Tests

- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
