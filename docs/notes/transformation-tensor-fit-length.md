# Transformation `tensor.fitLength`

> Füllt eine Achse auf oder kürzt sie; `keep: end` behält die jüngsten Werte (Zeitreihen-Fenster).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `tensor`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `length` | ganze Zahl ≥ 1 | ja | – |
| `axis` | ganze Zahl | nein | `-1` |
| `value` | Zahl | nein | `0` |
| `keep` | `start` oder `end` | nein | `"start"` |

Hinweis: `length`, optional `axis` (Standard `-1`), `value` (Standard `0`), `keep` (`start` oder `end`)

## Fachliche Tests

- [`test_data_transforms.py`](../../local-runtime/python/tests/test_data_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
