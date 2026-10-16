# Schnittstelle des ML-Dienstes

> Ein ML-Dienst pro Server bedient alle Stacks; Runtimes sprechen ihn nur über Referenzen und ein Mandanten-Token an.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

Warum einer pro Server (`docker-compose.server.yaml`): Katalogmodelle liegen
so nur einmal auf der Platte und im Speicher; Teammodelle bleiben je Runtime
getrennt.

Adapter der Runtime: `SidecarOnnxInferenceRuntime`,
`HttpPythonInferenceSidecar`, alle Anfragen über `MlServiceHttp`. Dienst:
`novooa_ml.inference_server`.

```text
POST   /v1/tenants        {tenantId}   → 201 {token}; 409 tenant_exists   (ohne Anmeldung)
DELETE /v1/tenants/self                 Abmelden: Token ungültig, Teammodelle gelöscht
POST   /v1/models         {modelKey, source: global|team, files: [{path, sha256, sizeBytes, storePath?}]}
POST   /v1/bundles        {modelKey, source: global, files}   nur vorladen (Katalog-Cache)
PUT    /v1/bundles/:key/files/:path   Binärstream mit x-sha256 (nur Teammodelle)
POST   /v1/inferences     {modelKey, inputs, outputs}
POST   /v1/contract-validations       {contract}
GET    /v1/transformation-capabilities
```

Alle Anfragen außer der Anmeldung tragen `Authorization: Bearer <token>`.

## Siehe auch

- [ML-Mandanten](./ml-mandanten.md)
- [Ressourcen und Warteschlange des ML-Dienstes](./ml-ressourcen-und-warteschlange.md)
- [ONNX-Inferenz über den ML-Dienst](./onnx-inferenz-ml-dienst.md)
