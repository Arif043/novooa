# Transformation `text.piperPhonemes`

> Text → Piper-Phonem-IDs mit Start- und Endsymbol (espeak).

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `text` → `tensor`

**Modellspezifisch:** Eine der wenigen Ausnahmen von der Regel allgemeiner Transformationen ([Regeln](./regeln-fuer-transformationen.md)); das Verfahren ist an die Vorverarbeitung dieses Modells gebunden.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `language` | Text | ja | – |
| `phonemeIdMap` | Zuordnung | ja | – |

## Fachliche Tests

- [`test_text_steps.py`](../../local-runtime/python/tests/test_text_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Piper-Systemmodelle](./piper-systemmodelle.md)
