# Transformation `tensor.scale`

> Berechnet `wert × factor + offset`, z. B. `1/255` für Pixel oder zum Zurückrechnen normierter Ausgaben.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `factor` | Zahl | nein | `1` |
| `offset` | Zahl | nein | `0` |

Hinweis: optional `factor` (Standard `1`), `offset` (Standard `0`)

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_tensor_operations.py`](../../local-runtime/python/tests/test_tensor_operations.py)
- [`test_general_output_transforms.py`](../../local-runtime/python/tests/test_general_output_transforms.py)
- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
