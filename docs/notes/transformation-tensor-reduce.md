# Transformation `tensor.reduce`

> Verdichtet eine Achse, z. B. Token-Embeddings per Mittelwert zu einem Satzvektor.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `operation` | `mean` oder `sum` oder `max` oder `min` | ja | – |
| `axis` | ganze Zahl | nein | `-1` |

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_classic_ml.py`](../../local-runtime/python/tests/test_classic_ml.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
