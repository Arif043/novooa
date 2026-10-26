# Transformation `audio.wav`

> Kodiert Samples als WAV-Datei (16 Bit, mono); Werte außerhalb von -1…1 werden begrenzt.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `tensor` → `audioFile`

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `sampleRate` | ganze Zahl ≥ 1 | ja | – |
| `fileName` | Text | nein | `"sprach-ausgabe.wav"` |

Hinweis: `sampleRate`, optional `fileName` (Standard `sprach-ausgabe.wav`)

## Beispiel

Aus `local-runtime/system-models/piper-de-eva-x-low.json`:

```json
{"type": "audio.wav", "result": "audio", "parameters": {"sampleRate": 16000, "fileName": "piper-de-eva.wav"}}
```

## Fachliche Tests

- [`test_audio_output.py`](../../local-runtime/python/tests/test_audio_output.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
- [Typebenen eines Modellvertrags](./modell-typebenen.md)
