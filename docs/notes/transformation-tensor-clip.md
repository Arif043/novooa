# Transformation `tensor.clip`

> Begrenzt Werte auf den Bereich zwischen `min` und `max`.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `min` | Zahl | nein | – |
| `max` | Zahl | nein | – |

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
