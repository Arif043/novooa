# Anmeldepflicht der Runtime

> Jede Verbindung zur Runtime, auch lokal auf demselben Rechner, braucht eine Sitzung eines Benutzerkontos.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

Nach der Anmeldung (`POST /v1/auth/login {loginName, password}`) schickt der
Client sein Session-Token als `Authorization: Bearer <token>`. Der Session-Hook
setzt daraus `request.actor = {uid, role}`; Routen lesen die Person nur dort
(siehe [Benutzerkonten der Runtime](./runtime-benutzerkonten.md)).

Ohne Sitzung erreichbar:

- `/healthz`
- `GET /v1/license`, `POST /v1/license/activate` — geschützt durch den
  Lizenz-Token selbst
- `/hooks/*` — siehe [Webhooks: Ausnahme von der Sitzungspflicht](./webhook-sitzungsausnahme.md)
- `GET`/`POST /v1/setup`, `POST /v1/auth/login`,
  `POST /v1/auth/invitations/redeem`, `POST /v1/auth/recover`
- `POST /v1/license/release` nur **vor** der Ersteinrichtung; danach braucht
  es die Sitzung eines Admins (sonst `401` bzw. `403 admin_required`)
- Diese Routen überspringen nur die Session-, nicht die Lizenzprüfung.

Mit Migration 0025 (Benutzerkonten) wurden das frühere gemeinsame
Betreiber-Passwort und alle Sitzungen gelöscht: Bestehende Runtimes richten
sich nach dem Update einmal neu ein ([Ersteinrichtung](./runtime-ersteinrichtung.md)).

## Siehe auch

- [Ersteinrichtung der Runtime](./runtime-ersteinrichtung.md)
- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [Anfrage-Pipeline: Lizenz → Session → Route](./runtime-anfrage-pipeline.md)
