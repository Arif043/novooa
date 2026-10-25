# Webhooks: Ausnahme von der Sitzungspflicht

> `POST|PUT /hooks/:triggerId/:token` braucht keine Sitzung; das Plugin prüft selbst Lizenz und Token der Adresse.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Das Plugin `webhookRoutes` liegt neben der API, nicht in ihr.
- Ohne Lizenz `423`; Authentifizierung über das Token der Adresse, optional
  zusätzlich per HMAC-Signatur.
- Fehlversuche und Aufrufe je Auslöser sind begrenzt.
- Die Runtime muss dafür öffentlich erreichbar sein
  ([Reverse Proxy](./reverse-proxy-externer-zugriff.md) mit `https`).

## Siehe auch

- [Webhooks](../index/webhooks.md)
- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
