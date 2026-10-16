# Webhook-Ereignis im Lauf

> Der Lauf bekommt den Aufruf als `input.event`; der Baustein „Webhook-Ereignis“ (`readWebhook`) macht Inhalt, Methode, Query, Kopfzeilen und Zeitpunkt als Werte verfügbar.

Gehört zu: [Webhooks](../index/webhooks.md)

```json
{
  "type": "webhookReceived", "method": "POST",
  "query": {"a": "1"}, "headers": {"content-type": "application/json"},
  "body": {"bestellung": 42}, "receivedAt": "2026-10-05T10:00:00.000Z"
}
```

- `body`: JSON und `application/x-www-form-urlencoded` als Objekt, alles
  andere (auch ungültiges JSON) als Text.
- `headers` **ohne** `authorization`, `proxy-authorization`, `cookie`,
  `set-cookie` und die Signatur-Kopfzeile.
- Der lesbare Kontext („Webhook empfangen, Methode, Inhaltstyp, Größe“)
  enthält weder Token noch Inhalt.

| Ausgabe | Typ | Inhalt |
| --- | --- | --- |
| `{{ereignis}}` / `{{ereignis.feld}}` | `json` (bei Text `string`) | Inhalt; JSON-Felder direkt, z. B. `{{ereignis.bestellung}}` |
| `{{Methode}}` (`method`) | `string` | `POST` oder `PUT` |
| `{{Abfrage}}` (`query`) | `json` | Query-Parameter |
| `{{Kopfzeilen}}` (`headers`) | `json` | gefilterte Kopfzeilen |
| `{{Empfangen}}` (`receivedAt`) | `datetime` | Empfangszeit |

Ein nicht per Webhook gestarteter Lauf bricht ab mit „Dieser Lauf wurde nicht
durch einen Webhook gestartet“. Der KI-Agent kennt den Baustein nicht.

## Siehe auch

- [Webhook-Auslöser](./webhook-ausloeser.md)
- [Registrierte Executor-Outputs](./executor-outputs.md)
