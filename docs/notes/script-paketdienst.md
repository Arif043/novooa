# Script-Paketdienst

> `novooa-packages` installiert PyPI-Pakete mit uv in Umgebungen auf dem Volume `novooa-script-packages`; der Script-Container liest es nur.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Code: `functions/Dockerfile.script-packages`,
  `local-runtime/python/novooa_packages/`. Gleiche Python-Basis wie der
  Script-Container (`python:3.12-slim`), damit die Binärpakete dort laufen;
  beide Dockerfiles nur gemeinsam anheben. uv in fester Version.
- Adresse: `SCRIPT_PACKAGES_URL` (Compose: `http://novooa-packages:8092`).
  Ohne sie antworten die Paket-Routen der Runtime mit 503.
- **API:** `GET /environments` → `{items: [{id, packages, sizeBytes}]}`;
  `POST /environments` `{id, packages}` installiert (blockiert bis fertig,
  höchstens 15 Minuten) oder antwortet `422 {reason, detail}`;
  `DELETE /environments/<id>`; `GET /healthz`.
- **Ablauf:** `uv pip compile --generate-hashes --only-binary :all:` →
  `lock.txt`, dann `uv pip install --require-hashes --no-deps --target site`
  in `.building/`, Größenprüfung
  (`SCRIPT_PACKAGES_MAX_ENVIRONMENT_BYTES`, Standard 2 GB), atomares
  Umbenennen nach `envs/<id>/`. Eine Installation zur Zeit.
- **Sicherheit:** nur fertige Pakete (Wheels) — beim Installieren läuft kein
  Code der Pakete; Paketangaben ohne URLs, Pfade und Optionen. Kein Root,
  `cap_drop: ALL`, schreibgeschütztes Dateisystem; schreiben darf der Dienst
  nur ins Volume. Der uv-Cache liegt im selben Volume (Hardlinks).
- **Netze:** `novooa-packages` (intern, zur Runtime) und
  `novooa-packages-egress` (nach außen, zu PyPI). Der Script-Container bleibt
  ohne Netz und bindet das Volume schreibgeschützt ein.
- **Volume-Rechte:** Das Image legt `/packages` für UID 65532 an; ein neues
  Volume übernimmt das beim ersten Einbinden. Deshalb startet
  `novooa-script` erst nach `novooa-packages`.

## Siehe auch

- [Script: Python-Pakete](./script-pakete.md)
- [Script-Dienst: Abschottung](./script-dienst-abschottung.md)
- [Ports und Netze der Runtime](./runtime-ports-und-netze.md)
