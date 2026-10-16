# Caches im Cloud-Run-Dienst

> Der Sidecar lädt Bündel beim ersten Zugriff einer warmen Instanz nach `/tmp` (im Arbeitsspeicher); ein verworfener Cache-Eintrag führt zu genau einem Neuladen.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Das Gateway prüft Manifest und Verfügbarkeit und schickt nur Referenzen.
- Der Sidecar lädt aus `MODEL_STORE_URL`; weil `/tmp` in Cloud Run RAM ist,
  begrenzen `MODEL_BUNDLE_MAX_BYTES` und `MODEL_SESSION_CACHE_BYTES` beides.
- Verworfene Session: `404 model_not_loaded` → das Gateway lädt dieselbe
  unveränderliche Version erneut und wiederholt nur diese Inferenz.
- Caches sind flüchtig; der globale Modellspeicher ist die geprüfte Quelle.

Vorlage `functions/cloudrun/model-inference-service.yaml.template`:
Concurrency `1`, höchstens zehn Instanzen, eine warm. Vor dem Deploy
`NODE_IMAGE`, `SIDECAR_IMAGE` und `MODEL_STORE_URL` ersetzen.

## Siehe auch

- [Cloud-Inferenzdienst](./cloud-inferenzdienst.md)
- [Modellbündel](./modellbuendel.md)
