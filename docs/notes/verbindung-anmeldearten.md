# Anmeldearten einer Verbindung

> Verbindungen melden sich per API-Key-Header, Bearer-Token oder OAuth client credentials an; das OAuth-Token holt und cacht die Runtime selbst.

Gehört zu: [Verbindungen](../index/verbindungen.md)

- **API-Key im Header:** `<Header-Name>: <Key>`; Name aus Buchstaben, Ziffern
  und `-` (z. B. `X-API-Key`).
- **Bearer-Token:** `Authorization: Bearer <Token>`.
- **OAuth client credentials:** POST an die Token-URL
  (`application/x-www-form-urlencoded`: `grant_type`, `client_id`,
  `client_secret`, optional `scope`; mit „Token-Anfrage als JSON senden“
  (`tokenRequestFormat: "json"`) als JSON-Body), gesendet als Bearer.
  - Token im Speicher bis 60 s vor Ablauf (`expires_in`; fehlt es: 300 s).
  - Gleichzeitige Aufrufe teilen sich eine Token-Anfrage.
  - Nach Bearbeiten der Verbindung gilt ein neues Token.
  - Fehlermeldungen nennen Status und Grund des Servers, nie das Geheimnis.

Nicht umgesetzt: Basic Auth, delegiertes OAuth (Nutzer verbindet eigenes
Konto; braucht Redirect-URL der Runtime), andere Token-Formate wie
HTTP-Basic am Token-Endpunkt.

## Siehe auch

- [Verbindung](./verbindung.md)
