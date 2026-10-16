# Piper-Systemmodelle

> Zwei deutsche Text-zu-Sprache-Systemmodelle auf Basis von Piper: Thorsten (mittlere Qualität, natürlicher) und Eva `x_low` (klein, schnell).

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Manifeste:
  [`piper-de-eva-x-low.json`](../../local-runtime/system-models/piper-de-eva-x-low.json),
  [`piper-de-thorsten-medium.json`](../../local-runtime/system-models/piper-de-thorsten-medium.json),
  inklusive Phonemzuordnung.
- ONNX-Artefakte werden per `models:publish` im globalen Modellspeicher
  veröffentlicht.
- `text.piperPhonemes` und `text.piperPhonemeLength` bereiten den Text vor,
  `tensor.constant` liefert die im Baustein eingestellten Parameter
  (`scales`), `audio.wav` serialisiert die Wellenform als Audio-Ausgabewert.

## Siehe auch

- [Modell-Settings](./modell-settings.md)
- [Sprachausgabe](../index/sprachausgabe.md)
