# Transformation `tensor.channelOrder`

> Ordnet Farbkanäle über eine vollständige Indexpermutation um.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `order` | Liste aus ganze Zahl ≥ 0 | ja | – |

Hinweis: `order`, etwa `[2, 1, 0]`

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "tensor.channelOrder", "parameters": {"order": [2, 1, 0]}}
```

## Fachliche Tests

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
