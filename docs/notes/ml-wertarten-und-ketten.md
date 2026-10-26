# Wertarten und Kettenregeln

> Jede Transformation deklariert, welche Wertarten sie annimmt (`accepts`) und liefert (`produces`); eine Pipeline ist gültig, wenn die Arten lückenlos aneinanderpassen.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Wertart | Entsteht durch | Angenommen von (Beispiele) |
| --- | --- | --- |
| `image` | Quelle `image`, `image.*` | `image.*`, Tensorschritte (implizit); `image.tiles` und `image.sizeTensor` liefern `tensor` |
| `audio` | Quelle `audio`, `audio.mono` … | `audio.*`, Tensorschritte (implizit); `audio.frames` liefert `tensor` |
| `text` | Quelle `text` | `text.piper*`, `text.kokoro*` |
| `datetime` | Quelle `datetime` (ISO 8601, ohne Versatz UTC) | `datetime.features` |
| `number` / `json` | Quellen `number` bzw. `json`/`boolean` | `number.toTensor` bzw. `json.toTensor`, `json.features` |
| `tensor` | Modellausgang, `audio.melSpectrogram`, `text.*`, `json.*`, `tensor.*` | alle `tensor.*`, `mask.*`, `sequence.*`, `audio.wav` |
| `regions` | `mask.connectedComponents`, `mask.textRegions` | `geometry.mergeRows`, `geometry.scaleBounds`, `geometry.toSource` |
| `detections` | `tensor.nonMaximumSuppression` | `geometry.toSource`, `resource.lookup`; sonst Kettenende |
| `keypoints` | `keypoints.fromRows`, `keypoints.fromHeatmaps`, `keypoints.fromSimcc` | `geometry.toSource`, `resource.lookup`; sonst Kettenende |
| `imageFile` | `image.encode`, `image.applyMask` | Kettenende; Workflow-Typ `image` |
| `json-result` | `tensor.topK`, `tensor.nonMaximumSuppression`, `sequence.*` | Kettenende; weiter über das Mapping |
| `audioFile` | `audio.wav` | Kettenende; Workflow-Typ `audio` |

**Kettenregeln**

- Ein Eingang beginnt mit der Art seiner Quelle und endet bei `tensor`;
  `image` und `audio` gelten ohne eigenen Schritt als Tensor.
- Ein Ausgang beginnt bei `tensor` und darf mit jeder Art enden.
- `tensor.constant` nimmt jede Art an.
- Quellen vom Typ `tensor` gehen unverändert ans Modell, ohne
  Transformationen.
- Ausgangspipelines dürfen weitere **Rohausgänge** des Modells lesen
  (`tensor.concat`, `keypoints.fromSimcc`), auch solche ohne eigenen
  Vertragsausgang. Solche Parameter haben das Schema `outputName`; die
  Veröffentlichung prüft, dass es den Ausgang gibt.

Damit ist jede Transformation in beiden Richtungen nutzbar, z. B.
`tensor.layout` und `tensor.normalize` am Ausgang eines Bildmodells.

## Siehe auch

- [Vertragsprüfung](./ml-vertragspruefung.md)
- [Transformationen](../index/transformationen.md)
