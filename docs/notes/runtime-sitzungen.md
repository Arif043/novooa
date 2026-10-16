# Runtime-Sitzungen

> Sitzungen laufen nach 7 Tagen ohne Nutzung ab; ein Sitzungsende erkennt der Client nur am Code `session_required`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Laufzeit:** Jede Anfrage verlängert auf 7 Tage; geschrieben wird höchstens
  einmal pro Stunde. Abgelaufene Sitzungen räumt der nächste Login weg.
  Gespeichert wird nur der SHA-256-Hash des Tokens.
- **Abmelden:** `POST /v1/auth/logout` (`204`). Ist die Runtime nicht
  erreichbar, meldet die App trotzdem ab; das Token verfällt von selbst.
- **Andere Geräte abmelden:** `POST /v1/auth/sessions/revoke-others` →
  `{revoked: <Anzahl>}`. UI: Einstellungen → Allgemein → „Angemeldete Geräte“.
- **Sitzung beendet:** `401 {code: "session_required"}`. Nur darauf (nicht auf
  andere `401` wie `license_rejected`) meldet `SessionAwareWorkspaceApiClient`
  ein Sitzungsende: Realtime-Kanal schließen, Token löschen, Anmeldung mit
  Hinweis zeigen. Adresse und Variantenwahl bleiben.
- **Realtime:** Das WebSocket-Ticket ist an die anfordernde Sitzung gebunden.
  Abmelden schließt deren Verbindungen sofort mit Code `4401`; zusätzlich
  prüft die Runtime jede Minute Sitzung und Lizenz offener Verbindungen.

Das Token liegt im Client im [sicheren Speicher](./client-token-speicher.md).

## Siehe auch

- [Betreiber-Passwort-Pflicht](./betreiber-passwort-pflicht.md)
- [Passwort ändern](./passwort-aendern.md)
