# Passwort ändern

> Ein angemeldeter Betreiber setzt das Passwort über `PUT /v1/auth/password` neu, ohne das alte oder den Lizenz-Token anzugeben.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

UI: **Einstellungen → Allgemein → Passwort neu setzen**. Ein einzelnes Feld
mit Klartext-Umschaltung, kein Bestätigungsfeld; nach dem Speichern wird es
geleert und verborgen.

- Antwort `204`. Verlangt aktive Lizenz und gültige Sitzung (`423` bzw.
  `401 session_required`).
- 6–1000 Zeichen; Leerzeichen bleiben erhalten.
- SQLite speichert einen neuen scrypt-Hash mit frischem Salt; das alte
  Passwort gilt sofort nicht mehr.
- Bestehende Gerätesitzungen bleiben angemeldet; sie lassen sich über
  „Angemeldete Geräte“ beenden.

## Siehe auch

- [Runtime-Sitzungen](./runtime-sitzungen.md)
- [Login-Ratenbegrenzung](./login-ratenbegrenzung.md)
