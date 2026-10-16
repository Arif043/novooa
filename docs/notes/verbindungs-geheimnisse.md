# Geheimnisse von HTTP-Verbindungen

> Zugangsdaten gespeicherter HTTP-Verbindungen liegen verschlüsselt in `language_model_secrets` mit Präfix `connection/` und werden bei der Schlüsselrotation mitgenommen.

Gehört zu: [Lokale Runtime](../index/lokale-runtime.md)

- Endpunkte `/v1/connections…`, Realtime-Thema `connections`; genutzt vom
  Baustein „HTTP-Anfrage“.
- Ausgehende Anfragen haben **keine** Sperre für interne Adressen.

## Siehe auch

- [Verbindungen](../features/verbindungen.md) § Sicherheit
- [Feldverschlüsselung mit Envelopes](./feldverschluesselung-envelope.md)
