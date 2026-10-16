# Lokaler Inferenz-Stack

> Für Entwicklung läuft der Cloud-Inferenzdienst per Docker Compose lokal, nur mit einem lesend eingebundenen Runtime-Ordner, ohne Firebase und Google-Anmeldedaten.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

```bash
docker compose -f docker-compose.model-inference.yaml up --build
```

- Erreichbar nur unter `http://127.0.0.1:8080`. Für den Functions-Emulator in
  `functions/.env.local`: `MODEL_INFERENCE_SERVICE_URL=http://127.0.0.1:8080`;
  dort ohne ID-Token. Außerhalb des Emulators nur HTTPS mit Cloud-Run-ID-Token.
- Modelle vorher auf dem Host installieren (der Gateway kann sie nie
  verändern):

  ```bash
  npm --prefix functions run models:install-local -- \
    --runtime-root .novooa \
    --manifest models/mobilenet-v3/model.json \
    --artifact models/mobilenet-v3/model.onnx
  ```

  Gewichte und Ressourcen wie beim Publishing (`--external-data`,
  `--resource`). Struktur:
  `.novooa/model-catalog/<base64url-modell-id>.json`,
  `.novooa/model-artifacts/<artifact-id>/versions/<version-id>/model.onnx`.
- Netze: Sidecar nur in `novooa-private` (kein Ausgang); Gateway zusätzlich in
  `novooa-public`, damit die `127.0.0.1`-Freigabe auf Docker Desktop
  funktioniert.
- Der Emulator ist kein vollständig lokaler Runner: Aufgaben, Dateien und
  Runs kommen dort aus Firebase. Vollständig lokal ist die
  [Lokale Runtime](../index/lokale-runtime.md).

## Siehe auch

- [Cloud-Inferenzdienst](./cloud-inferenzdienst.md)
