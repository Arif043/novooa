# Transformation `tensor.topK`

> Liefert die `k` größten Werte als Paare aus Index und Wert.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `json-result`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `k` | ganze Zahl ≥ 1 | nein | – |
| `parameter` | Objekt mit `name`, `label`, `default`, `minimum`, `maximum` | nein | – |

Hinweis: `k` (Zahl oder Setting-Bindung wie `"$anzahl"`), optional `result`; veraltet `parameter` (wird beim Lesen zu einem Setting)

## Beispiel

`k` aus dem Setting `anzahl` ([Modell-Settings](./modell-settings.md)), Ergebnis
als `topClasses` für das Workflow-Mapping:

```json
{"type": "tensor.topK", "result": "topClasses", "parameters": {"k": "$anzahl"}}
```

## Fachliche Tests

- [`test_inference_server.py`](../../local-runtime/python/tests/test_inference_server.py)
- [`test_tensor_steps.py`](../../local-runtime/python/tests/test_tensor_steps.py)
- [`test_resource_lookup.py`](../../local-runtime/python/tests/test_resource_lookup.py)
- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Modell-Settings](./modell-settings.md)
