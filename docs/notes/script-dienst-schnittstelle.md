# Script-Dienst: Schnittstelle

> In Standalone läuft Python eines Script-Bausteins nie in der Runtime, sondern im Container `novooa-script` über `POST /run`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Code: `functions/Dockerfile.script-runner`,
  `local-runtime/python/novooa_script/`.
- Adresse: `SCRIPT_RUNNER_URL` (Compose: `http://novooa-script:8091`). Ohne
  sie läuft **kein** Script; es gibt keinen Rückfall auf Python in der
  Runtime. Der Node-Container enthält kein Python.
- `POST /run` als `multipart/form-data`: Teil `request` (JSON: Script,
  gelesene Werte `inputs`, Datei-Metadaten), danach je Datei ein Teil `file-<n>`
  mit rohen Bytes (kein Base64). Anhänge zusammen höchstens 25 MB
  (`maximumAttachmentBytes`).
- Optional `environment`: ID der [Paketumgebung](./script-pakete.md); fehlt
  sie unter `/packages/envs/<id>`, antwortet der Dienst `409
  {code: "packagesMissing"}`.
- Antwort `200` mit `printed`, `stderr`, `workflowOutputs` oder `422` mit
  lesbarer Meldung samt Script-Zeile.
- `POST /probe` als JSON `{environment, packages}`: lädt die Pakete einer
  Umgebung unter den Grenzen eines Laufs und antwortet `200 {loadable, module?,
  error?}`; fehlt die Umgebung, `409` wie bei `/run`
  ([Paketprobe](./script-paketprobe.md)).

**Cloud:** Die Functions führen Scripts weiter mit `python3` im eigenen
Prozess und eingeschränkten Builtins aus (`createPythonScriptExecutor`).

## Siehe auch

- [Script-Dienst: Ausführung und Grenzen](./script-dienst-ausfuehrung.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
- [Script: Workflow-Ausgabewerte](./script-workflow-output.md)
