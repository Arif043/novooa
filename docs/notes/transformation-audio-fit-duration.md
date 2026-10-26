# Transformation `audio.fitDuration`

> Füllt mit Stille auf oder kürzt auf eine feste Dauer.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `audio`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `seconds` | Zahl ≥ 0 | ja | – |
| `keep` | `start` oder `end` | nein | `"start"` |

## Fachliche Tests

- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
