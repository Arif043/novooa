# Transformation `json.toTensor`

> Zahlen und Wahrheitswerte → `float32`-Tensor, Texte → String-Tensor, jeweils auch als gleich lange (verschachtelte) Listen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `json` → `tensor`

Gemischte Listen sind ein Fehler.

## Parameter

Keine.

## Fachliche Tests

- [`test_classic_ml.py`](../../local-runtime/python/tests/test_classic_ml.py)
- [`test_data_transforms.py`](../../local-runtime/python/tests/test_data_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Klassisches ML über ONNX](./klassisches-ml-onnx.md)
