# Globaler Modellspeicher

> Dateien globaler Modelle liegen öffentlich lesbar im S3-kompatiblen Hetzner Object Storage; jeder Beteiligte leitet den Ort aus der logischen Referenz ab.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Layout unter `model-artifacts/{artifactId}/versions/{versionId}/`:

- `model.onnx`
- ausgelagerte Gewichte (`externalData`) unter ihrem Namen daneben
- Ressourcen unter `resources/`

Es gibt keine eigene Distribution. Modellbytes laufen weder über Firestore
noch über novooa-Functions noch über die Runtime, sondern direkt in den
ML-Dienst (`MODEL_STORE_URL` bzw. `NOVOOA_MODEL_STORE_URL`). Modellversionen
sind unveränderlich.

Eigene Modelle der Runtime nutzen dasselbe Layout unter dem Runtime-Root;
der Pfad ist nie Teil eines Katalogeintrags oder Workflow-Werts.

## Siehe auch

- [Modelle veröffentlichen](./modelle-veroeffentlichen.md)
- [Modellbündel](./modellbuendel.md)
