# Transformation `audio.normalize`

> Gleicht die Lautstärke an; Stille bleibt unverändert.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `audio`

`zscore` standardisiert je Kanal: `(x − Mittelwert) / sqrt(Varianz + 1e-7)`, wie die
Feature-Extractors von Wav2Vec2 und HuBERT; `target` gilt dort nicht.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `mode` | `peak` oder `rms` oder `zscore` | nein | `"peak"` |
| `target` | Zahl ≥ 0 | nein | – |

Hinweis: optional `mode` (`peak` oder `rms`), `target` (Standard `1` bzw. `0.1`)

## Fachliche Tests

- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
