# Cloud-Inferenzdienst

> In der Cloud läuft Inferenz in einem privaten Cloud-Run-Dienst (Node-Gateway + Python-Sidecar) mit denselben Use Cases wie Standalone.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- `RunModelInferenceWithSources` mit Firestore als `ModelCatalog` und dem
  globalen Modellspeicher als Quelle (`GlobalModelBundleSources`). ONNX
  Runtime und Transformationen laufen im Sidecar.
- HTTP-Adapter nimmt nur transportierbare Werte:

  ```text
  POST /v1/inferences
  { teamId, modelId, inputs: [{type, ...}] }
  ```

  Bild- und Dateiquellen als Base64, Tensoren mit `name`, `dataType`,
  `shape`, `dataBase64`; Antwort im selben Format, gegen das Manifest
  validiert. Keine Firebase-Pfade.
- Aufruf: `runTaskRunTask` nutzt `CloudRunModelInference` mit Google-ID-Token.
  Service-URL im Functions-Parameter `MODEL_INFERENCE_SERVICE_URL`
  (`functions/.env.<projectId>`, vor dem Deploy setzen); die Function braucht
  `roles/run.invoker` auf genau diesem Dienst.
- Eigener Service-Account nur mit `roles/datastore.user`; der Modellspeicher
  ist öffentlich lesbar.
- `MODEL_INFERENCE_MODE=local`: derselbe Composition Root mit
  Dateisystemkatalog und `LocalDirectoryModelBundleSources`.

Bauen:

```bash
docker build -f functions/Dockerfile.model-inference -t novooa-model-inference .
gcloud builds submit --project=syscat-90bff --region=europe-west3 \
  --config=cloudbuild.model-inference.yaml \
  --substitutions=_IMAGE=europe-west3-docker.pkg.dev/syscat-90bff/novooa/model-inference:<version>
```

Der Container hört auf `0.0.0.0:$PORT` und bleibt privat.

## Siehe auch

- [Caches im Cloud-Run-Dienst](./cloud-run-ml-caches.md)
- [Lokaler Inferenz-Stack](./lokaler-inferenz-stack.md)
- [Inferenz-Use-Cases](./inferenz-use-cases.md)
