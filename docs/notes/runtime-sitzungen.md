# Runtime-Sitzungen

> Jede Sitzung gehört einem Konto und läuft nach 7 Tagen ohne Nutzung ab; ein Sitzungsende erkennt der Client nur am Code `session_required`.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- **Laufzeit:** Jede Anfrage verlängert auf 7 Tage; geschrieben wird höchstens
  einmal pro Stunde. Abgelaufene Sitzungen räumt der nächste Login weg.
  Gespeichert wird nur der SHA-256-Hash des Tokens.
- **Abmelden:** `POST /v1/auth/logout` (`204`). Ist die Runtime nicht
  erreichbar, meldet die App trotzdem ab; das Token verfällt von selbst.
- **Konto:** `runtime_sessions.uid` (Fremdschlüssel, wird mit dem Konto
  gelöscht). Die Prüfung liefert `{uid, role}`; ohne Mitgliedschaft im aktiven
  Team gilt die Sitzung nicht.
- **Geräteangaben:** Login, Einladung und Notzugang nehmen optional
  `device: {app, os, browser}` an (Selbstauskunft des Clients, nur Anzeige;
  gekürzt in `SessionDevice`). Der Client sendet sie über
  `HttpRuntimeLoginClient(device: RuntimeDevice.current(app: …))`; die App
  meldet `novooa`, Kunden-Dashboards ihren Namen. Rechnername und IP werden
  nicht erfasst.
- **Angemeldete Geräte:** `GET /v1/auth/sessions` →
  `{items: [{id, current, createdAt, lastUsedAt, device}]}`, nur das eigene
  Konto, zuletzt aktive zuerst. `lastUsedAt` wird mit der Verlängerung
  geschrieben, also höchstens stündlich genau.
- **Ein Gerät abmelden:** `DELETE /v1/auth/sessions/:id` (`204`); fremde,
  unbekannte oder die eigene Sitzung → `404 session_not_found`. Die eigene
  endet über `logout`.
- **Andere Geräte abmelden:** `POST /v1/auth/sessions/revoke-others` →
  `{revoked: <Anzahl>}`, nur Sitzungen des eigenen Kontos.
- **UI:** Einstellungen → Allgemein → „Angemeldete Geräte“: Liste mit Gerät
  (z. B. „Chrome auf macOS“), „Angemeldet am“, „Zuletzt aktiv“, Markierung
  „Dieses Gerät“ und je anderem Gerät „Abmelden“ mit Rückfrage; darunter
  „Andere Geräte abmelden“. Beendete Sitzungen schließen ihre
  Realtime-Verbindungen sofort.
- **Konto gelöscht oder zurückgesetzt:** alle Sitzungen des Kontos enden sofort,
  offene Realtime-Verbindungen werden geschlossen
  ([Benutzerkonten](./runtime-benutzerkonten.md)).
- **Sitzung beendet:** `401 {code: "session_required"}`. Nur darauf (nicht auf
  andere `401` wie `license_rejected`) meldet `SessionAwareWorkspaceApiClient`
  ein Sitzungsende: Realtime-Kanal schließen, Token löschen, Anmeldung mit
  Hinweis zeigen. Adresse und Variantenwahl bleiben; nach der erneuten
  Anmeldung lädt die App das Konto neu (es kann eine andere Person sein).
- **Realtime:** Das WebSocket-Ticket ist an die anfordernde Sitzung gebunden.
  Abmelden schließt deren Verbindungen sofort mit Code `4401`; zusätzlich
  prüft die Runtime jede Minute Sitzung und Lizenz offener Verbindungen.

Das Token liegt im Client im [sicheren Speicher](./client-token-speicher.md).

## Siehe auch

- [Anmeldepflicht der Runtime](./runtime-anmeldepflicht.md)
- [Passwort ändern](./passwort-aendern.md)
- [Geräte der Sitzungen (0027)](./sqlite-sitzungsgeraete-0027.md)
