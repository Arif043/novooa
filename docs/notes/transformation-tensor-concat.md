# Transformation `tensor.concat`

> Hängt Rohausgänge des Modells an den aktuellen Tensor an, etwa Scores und Labels an die Boxen.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

So werden getrennte Ausgänge — Boxen, Scores, Labels — zu einer Zeile je Erkennung. Ein Tensor mit einer Dimension weniger erhält eine Achse der Größe 1 (`[1, 300]` neben `[1, 300, 4]`); verschiedene Datentypen werden zu float32. Lesbar sind alle Ausgänge des ONNX-Modells, auch solche ohne eigenen Vertragsausgang; die Veröffentlichung prüft, dass es die genannten Ausgänge gibt.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `outputs` | Liste aus Name eines Modellausgangs | ja | – |
| `axis` | ganze Zahl | nein | `-1` |

## Beispiel

Ausgang `pred_boxes` eines RT-DETR- oder D-FINE-Exports; danach `tensor.squeeze` und `tensor.nonMaximumSuppression`.

```json
{"type": "tensor.concat", "parameters": {"outputs": ["logits"]}}
```

## Fachliche Tests

- [`test_output_references.py`](../../local-runtime/python/tests/test_output_references.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Objekterkennung und Segmentierung](./objekterkennung-und-segmentierung.md)
