# ML-Katalogeintrag

> Ein Katalogeintrag beschreibt ein ONNX-Modell, seinen logischen Artefaktverweis und das vollständige Manifest, aber nie Firebase-Pfade oder Download-URLs.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

`scope` trennt Verfügbarkeit von Ablage:

- `system`: novooa stellt das Modell allen Teams bereit.
- `team`: teamweit bereitgestellt (eigene Importe in der Runtime).

```ts
{
  id: "mobilenet-v3",
  title: "MobileNet V3",
  description: "Klassifiziert ein Bild.",
  task: "image-classification",
  languages: [],
  tags: ["leichtgewichtig"],
  scope: {type: "system"},
  runtime: "onnx",
  artifactReference: {
    artifactId: "mobilenet-v3-artifact",
    versionId: "2026-08",
    format: "onnx",
    contentType: "application/onnx",
    sizeBytes: 10500000,
    sha256: "<sha-256>",
    // optional: Gewichte > 2 GB als ONNX External Data neben model.onnx
    externalData: [{name: "model.onnx.data", sizeBytes: 4200000000, sha256: "<sha-256>"}],
  },
  contract: {inputs: [...], settings: [...], outputs: [...]},
}
```

Vor der Inferenz werden alle Artefakte gegen Größe und SHA-256 geprüft. Das
Manifest wird im globalen Katalog (Firestore) und in SQLite identisch
gespeichert.

## Siehe auch

- [Globaler Modellspeicher](./globaler-modellspeicher.md)
- [Modellaufgaben, Sprachen und Tags](./modellaufgaben-und-sprachen.md)
- [Typebenen eines Modellvertrags](./modell-typebenen.md)
