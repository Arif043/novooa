# Transformation `json.features`

> Datensatz → Merkmalsvektor in fester Reihenfolge; `field` als Punktpfad, `kind` `number` (standardisiert mit `mean`/`std`), `boolean` oder `category` (One-Hot, unbekannte Werte `zero` oder `error`).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `json` → `tensor`

Eine Liste von Datensätzen ergibt eine Zeile je Datensatz.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `features` | Liste aus Objekt mit `field`, `kind`, `mean`, `std`, `default`, `categories`, `unknown` | ja | – |

Hinweis: `features` (Liste aus `{field, kind?, mean?, std?, default?, categories?, unknown?}`)

## Fachliche Tests

- [`test_classic_ml.py`](../../local-runtime/python/tests/test_classic_ml.py)
- [`test_data_transforms.py`](../../local-runtime/python/tests/test_data_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Klassisches ML über ONNX](./klassisches-ml-onnx.md)
