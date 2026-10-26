# Transformation `tensor.transpose`

> Ordnet die Achsen eines Tensors nach einer vollständigen Permutation um.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Für Farbkanäle von Bildern bleibt `tensor.layout` vorzuziehen, weil `tensor.normalize` dessen Layout kennt.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `axes` | Liste aus ganze Zahl ≥ 0 | ja | – |

Hinweis: `axes` (vollständige Permutation)

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)
- [`test_detector_formats.py`](../../local-runtime/python/tests/test_detector_formats.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
