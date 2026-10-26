# Transformation `audio.resample`

> Ändert die Abtastrate per Fourier-Resampling, z. B. auf 16 kHz.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `audio`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `sampleRate` | ganze Zahl ≥ 1 | ja | – |

## Fachliche Tests

- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
