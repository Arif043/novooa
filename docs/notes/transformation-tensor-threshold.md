# Transformation `tensor.threshold`

> Wandelt numerische Werte in eine boolesche Maske.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `value` | Zahl | nein | `0.5` |

Hinweis: optional `value` (Standard `0.5`)

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "tensor.threshold", "parameters": {"value": 0.3}}
```

## Fachliche Tests

- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
