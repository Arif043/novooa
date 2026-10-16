# Verbindung

> Eine Verbindung ist ein gespeicherter Zugang zu einem externen System — Basis-URL und Anmeldeart; das Geheimnis bleibt im Backend und kommt nie zum Client zurück.

Gehört zu: [Verbindungen](../index/verbindungen.md)

**Verfügbarkeit:** Standalone (`WorkspaceCapabilities.connections`). In der
Cloud fehlt der Baustein in der Palette; eine importierte Aufgabe bricht dort
mit verständlicher Meldung ab.

| Feld | Bedeutung |
| --- | --- |
| Name | 1–80 Zeichen |
| Basis-URL | `https://…` oder `http://…`, ohne Zugangsdaten, Query, Anker; abschließender `/` entfällt |
| Anmeldeart | siehe [Anmeldearten](./verbindung-anmeldearten.md) |
| Geheimnis | API-Key, Token oder Client-Secret (1–4096 Zeichen); Pflicht beim Anlegen |

- Antworten enthalten Name, Basis-URL und Anmeldeart, nie das Geheimnis.
  Leeres Geheimnis beim Bearbeiten = unverändert; bei Wechsel der Anmeldeart
  ist ein neues Pflicht.
- **„Verbindung testen“** (nur gespeicherte): GET auf Basis-URL plus
  optionalem Pfad; meldet Status und Hinweis (z. B. 401: „Prüfe die
  Zugangsdaten“).
- **Vorlage „Shopware“:** füllt Name, OAuth und JSON-Format vor, leitet die
  Token-URL ab (`<Shop>/api/oauth/token`), Test-Pfad `/api/_info/version`.
- **Speicher:** Tabelle `connections` (Migration `0007_connections.sql`).
  Geheimnis verschlüsselt in `language_model_secrets` mit
  `secret_ref = connection/<teamId>/<id>` — so erfasst die Schlüsselrotation
  es ohne Änderung (der Tabellenname passt nur historisch nicht). Löschen
  entfernt beides.
- **API:** `GET/POST /v1/connections`, `PUT/DELETE /v1/connections/:id`,
  `POST /v1/connections/:id/test` (immer 200; `ok` und `message` beschreiben
  das Ergebnis); Realtime-Thema `connections`.
- **Export:** Verbindungen und Geheimnisse gehören nicht dazu. Aufgaben
  verweisen per `connectionId`; auf einem anderen Gerät zeigt der Baustein
  „Verbindung nicht gefunden“, bis eine gewählt ist.

## Siehe auch

- [Baustein „HTTP-Anfrage“](./http-anfrage-baustein.md)
- [Feldverschlüsselung mit Envelopes](./feldverschluesselung-envelope.md)
- [Shopware einrichten](./shopware-einrichten.md)
