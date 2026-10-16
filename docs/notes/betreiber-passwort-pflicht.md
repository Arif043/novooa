# Betreiber-Passwort-Pflicht

> Jede Verbindung zur Runtime, auch lokal auf demselben Rechner, verlangt ein selbst gewähltes Betreiber-Passwort.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Das war ein bewusster Breaking Change: Bestehende Installationen müssen nach
dem Update einmalig ein Passwort setzen, bevor der native Client sich wieder
verbindet.

Nach der Anmeldung (`POST /v1/auth/login`) schickt der Client sein
Session-Token als `Authorization: Bearer <token>`.

Ausgenommen von der Passwort-Pflicht:

- `/healthz`
- `GET /v1/license`, `POST /v1/license/activate` — geschützt durch den
  Lizenz-Token selbst
- `/hooks/*` — siehe [Webhooks: Ausnahme von der Sitzungspflicht](./webhook-sitzungsausnahme.md)
- `POST /v1/license/release` nur **vor** der Ersteinrichtung; danach braucht
  es eine Sitzung (sonst `401`)
- Login und Setup überspringen nur die Session-, nicht die Lizenzprüfung.

## Siehe auch

- [Ersteinrichtung der Runtime](./runtime-ersteinrichtung.md)
- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [Anfrage-Pipeline: Lizenz → Session → Route](./runtime-anfrage-pipeline.md)
