# Modellordner und Manifestdatei

> Jedes Modell besteht mindestens aus `model.onnx` und einem versionierten `model.json`.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```text
models/mobilenet-v3/
├── model.onnx
└── model.json
```

```json
{
  "id": "mobilenet-v3",
  "title": "MobileNet V3",
  "description": "Klassifiziert Bilder.",
  "tags": ["bild", "klassifikation"],
  "artifact": {"artifactId": "mobilenet-v3", "versionId": "2026-08"},
  "contract": {
    "inputs": [{
      "name": "input", "source": "image", "dataType": "float32",
      "shape": ["dynamic", 3, 224, 224],
      "transformations": [
        {"type": "image.decode", "parameters": {"colorSpace": "rgb"}},
        {"type": "image.resize", "parameters": {"width": 224, "height": 224}},
        {"type": "tensor.layout", "parameters": {"order": "channelsFirst"}},
        {"type": "tensor.normalize", "parameters": {
          "mean": [0.485, 0.456, 0.406], "std": [0.229, 0.224, 0.225]}}
      ]
    }],
    "outputs": [{
      "name": "scores", "semantic": "classification.scores",
      "dataType": "float32", "shape": ["dynamic", 1000], "transformations": []
    }]
  }
}
```

Dazu kommen `task`, optional `languages`, `translations` und `settings`.

## Siehe auch

- [Modelle veröffentlichen](./modelle-veroeffentlichen.md)
- [ML-Katalogeintrag](./ml-katalogeintrag.md)
- [Mehrsprachige Manifeste](./mehrsprachige-manifeste.md)
