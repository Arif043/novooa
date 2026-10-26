# Transformation `audio.normalize`

> Gleicht die Lautstärke an; Stille bleibt unverändert.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `audio`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `mode` | `peak` oder `rms` | nein | `"peak"` |
| `target` | Zahl ≥ 0 | nein | – |

Hinweis: optional `mode` (`peak` oder `rms`), `target` (Standard `1` bzw. `0.1`)

## Fachliche Tests

- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
