# Volumes und Datenablage der Runtime

> `novooa-data` hält alle Teamdaten und ist nur in der Runtime beschreibbar; Schlüssel und ML-Daten liegen in eigenen Volumes.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

| Volume | Inhalt | Eingehängt in |
| --- | --- | --- |
| `novooa-data` | SQLite, Dateien, Wissensbasis, eigene Modelle, Skills | nur `novooa-runtime` (schreibbar) |
| `novooa-keys` | Master-Key-Schlüsselbund | Runtime, `key-init`, `key-rotation` |
| `novooa-ml-data` | Modellbündel, Mandantenliste | nur `novooa-ml` |
| `novooa-script-packages` | Paketumgebungen und uv-Cache der Script-Bausteine | `novooa-packages` (schreibbar), `novooa-script` (nur lesend) |

Compose legt sie als `novooa-local_novooa-data` und
`novooa-local_novooa-keys` an; `docker compose down` entfernt sie nicht.
Ein Backup umfasst immer **beide** Volumes.

Dateilayout im Datenverzeichnis:

```text
.novooa/
  files/{teamId}/{fileId}/versions/{versionId}/{fileName}
  model-artifacts/{artifactId}/versions/{versionId}/model.onnx   (nur eigene Modelle)
  knowledge/{teamId}/...
```

Der ML-Dienst bekommt keine Datenbank: Teammodelle streamt ihm die Runtime,
Katalogmodelle lädt er aus dem globalen Modellspeicher
(`NOVOOA_MODEL_STORE_URL`). Jede Modelldatei wird vor der Nutzung gegen Größe
und SHA-256 geprüft.

## Siehe auch

- [Master-Key-Schlüsselbund](./master-key-schluesselbund.md)
- [ONNX-Inferenz über den ML-Dienst](./onnx-inferenz-ml-dienst.md)
- [Import/Export](../index/import-export.md) — Sicherung als ZIP
