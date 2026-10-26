# Transformation `tensor.layout`

> Ordnet Bildtensoren zwischen HWC (`channelsLast`) und CHW (`channelsFirst`) um.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

Ein Batch `[N, H, W, C]` (etwa aus `image.tiles`) wird je Bild umgeordnet.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `order` | `channelsFirst` oder `channelsLast` | ja | – |

## Beispiel

Aus `models/pp-ocr-v3/detector/model.json`:

```json
{"type": "tensor.layout", "parameters": {"order": "channelsFirst"}}
```

## Fachliche Tests

- [`test_image_geometry.py`](../../local-runtime/python/tests/test_image_geometry.py)
- [`test_general_input_transforms.py`](../../local-runtime/python/tests/test_general_input_transforms.py)
- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
