# Transformation `tensor.reshape`

> Formt den Tensor um; die Anzahl der Werte muss passen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `shape` | Liste aus ganze Zahl ≥ -1 | ja | – |

Hinweis: `shape` (positive Zahlen, höchstens einmal `-1`)

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
