# Sprachmodelle ohne eigene Team-ID (0010)

> Sprachmodellprofile hängen per Fremdschlüssel an ihrer Verbindung; das Team ergibt sich daraus.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- `connection_id` ist indiziert und Fremdschlüssel auf
  `language_model_connections`; Löschen einer Verbindung entfernt ihre Modelle
  per Kaskade.
- Verbindung, Modelle und verschlüsseltes Geheimnis löscht der lokale
  Konfigurationsadapter in einer Transaktion.
- `capabilities_json` bleibt flexibles JSON; Fachobjekte tragen weiter
  `teamId`.

## Siehe auch

- [SQLite-Normalisierungsschritte](./sqlite-normalisierungsschritte.md)
- [Sprachmodell-Anbieter](./sprachmodell-anbieter.md)
