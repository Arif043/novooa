# Transformation `tensor.constant`

> Ersetzt den Wert durch einen festen Zahlentensor, z. B. für Hilfseingänge mit Inferenzparametern.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** jede Wertart → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `values` | Liste aus Zahl | ja | – |

## Beispiel

Aus `local-runtime/system-models/piper-de-eva-x-low.json`:

```json
{"type": "tensor.constant", "parameters": {"values": ["$noiseScale", "$lengthScale", "$noiseWidth"]}}
```

## Fachliche Tests

- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Modell-Settings](./modell-settings.md)
- [Eingangsbindungen](./modell-eingangsbindungen.md)
