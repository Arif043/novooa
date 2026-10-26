# Transformation `tensor.softmax`

> Normalisiert Werte entlang der letzten Tensorachse.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `axis` | ganze Zahl | nein | `-1` |

Hinweis: optional `axis` (nur `-1`)

## Beispiel

Aus `models/squeezenet-1.1/model.json`:

```json
{"type": "tensor.softmax", "parameters": {"axis": -1}}
```

## Fachliche Tests

- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
