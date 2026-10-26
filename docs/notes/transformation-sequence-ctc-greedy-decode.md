# Transformation `sequence.ctcGreedyDecode`

> Dekodiert CTC-Logits in `{text, confidence}`; `allowedCharacters` begrenzt die Auswahl auf ein fachlich zulässiges Alphabet.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `json-result`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `labels` | Liste aus Text | ja | – |
| `blankIndex` | ganze Zahl ≥ 0 | ja | – |
| `applySoftmax` | Wahrheitswert | nein | `true` |
| `collapseRepeated` | Wahrheitswert | nein | `true` |
| `allowedCharacters` | Text | nein | – |

## Fachliche Tests

- [`test_output_transformations.py`](../../local-runtime/python/tests/test_output_transformations.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [OCR-Pipeline](./ocr-pipeline.md)
