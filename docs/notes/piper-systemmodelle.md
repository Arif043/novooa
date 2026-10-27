# Piper-Systemmodelle

> Drei deutsche Text-zu-Sprache-Systemmodelle auf Basis von Piper: Thorsten (mittlere Qualität, natürlicher), Thorsten Emotional (Emotionen als Sprecher) und Eva `x_low` (klein, schnell).

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Manifeste:
  [`piper-de-eva-x-low`](../../models/piper-de-eva-x-low/model.json),
  [`piper-de-thorsten-medium`](../../models/piper-de-thorsten-medium/model.json),
  [`piper-de-thorsten-emotional-medium`](../../models/piper-de-thorsten-emotional-medium/model.json),
  inklusive Phonemzuordnung; je Modell ein Journal-Eintrag im selben Ordner
  ([Modellkatalog](../index/modellkatalog.md)).
- ONNX-Artefakte werden per `models:publish` im globalen Modellspeicher
  veröffentlicht.
- `text.piperPhonemes` und `text.piperPhonemeLength` bereiten den Text vor,
  `tensor.constant` liefert die im Baustein eingestellten Parameter
  (`scales`), `audio.wav` serialisiert die Wellenform als Audio-Ausgabewert.

## Siehe auch

- [Modell-Settings](./modell-settings.md)
- [Sprachausgabe](../index/sprachausgabe.md)
