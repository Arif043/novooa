# Transformation `text.kokoroTokens`

> Text → Kokoro-Token-IDs, eingerahmt von Füll-Tokens.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `text` → `tensor`

**Modellspezifisch:** Eine der wenigen Ausnahmen von der Regel allgemeiner Transformationen ([Regeln](./regeln-fuer-transformationen.md)); das Verfahren ist an die Vorverarbeitung dieses Modells gebunden.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `language` | Text | ja | – |
| `tokenIdMap` | Zuordnung | ja | – |

## Fachliche Tests

- [`test_text_steps.py`](../../local-runtime/python/tests/test_text_steps.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Stimmen der Sprachausgabe](./sprachausgabe-stimmen.md)
