# Transformation `audio.melSpectrogram`

> Liefert ein Mel-Spektrogramm `[melBins, Frames]` aus Mono-Audio.

Gehört zu: [Transformationen](../index/transformationen.md)

**Wertart:** `audio` → `tensor`

`db` ist relativ zum Maximum; `dynamicRange` begrenzt den Abstand zum Maximum in der gewählten Einheit. Voreinstellungen entsprechen librosa.

## Parameter

| Parameter | Wert | Pflicht | Standard |
| --- | --- | --- | --- |
| `frameLength` | ganze Zahl ≥ 1 | nein | `400` |
| `hopLength` | ganze Zahl ≥ 1 | nein | `160` |
| `melBins` | ganze Zahl ≥ 1 | nein | `80` |
| `minFrequency` | Zahl ≥ 0 | nein | `0` |
| `maxFrequency` | Zahl ≥ 0 | nein | – |
| `power` | Zahl ≥ 0 | nein | `2` |
| `scale` | `power` oder `log` oder `log10` oder `db` | nein | `"power"` |
| `dynamicRange` | Zahl ≥ 0 | nein | – |
| `melScale` | `slaney` oder `htk` | nein | `"slaney"` |
| `filterNormalization` | `slaney` oder `none` | nein | `"slaney"` |
| `center` | Wahrheitswert | nein | `true` |

## Fachliche Tests

- [`test_audio_transforms.py`](../../local-runtime/python/tests/test_audio_transforms.py)

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Baustein „Audio transkribieren“](./audio-transkribieren-baustein.md)
