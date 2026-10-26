# Transformation `tensor.slice`

> Wählt einen Bereich entlang einer Achse; ein leerer Bereich ist ein Fehler.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `start` | ganze Zahl | ja | – |
| `end` | ganze Zahl | nein | – |
| `axis` | ganze Zahl | nein | `-1` |

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
