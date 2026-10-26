# Transformation `tensor.l2Normalize`

> Skaliert Vektoren auf Länge 1 für Ähnlichkeitsvergleiche; Nullvektoren bleiben unverändert.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `axis` | ganze Zahl | nein | `-1` |

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
