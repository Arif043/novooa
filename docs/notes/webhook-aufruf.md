# Ablauf eines Webhook-Aufrufs

> `POST` oder `PUT` auf `/hooks/:triggerId/:token` durchläuft Lizenz, Adressprüfung, Begrenzungen, Einrichtungsprüfung und Signatur, bevor ein Lauf startet.

Gehört zu: [Webhooks](../index/webhooks.md)

`GET` gilt nur für die Einrichtungsprüfung.

1. **Lizenz:** ohne aktive Lizenz `423`.
2. **Adresse:** Auslöser aktiv, Quelle `webhookReceived` (oder eine Quelle mit
   `usesWebhook`), Token gleich (SHA-256 und `timingSafeEqual`). Unbekannte
   Kennung, falsches Token und deaktivierter Auslöser sehen gleich aus: `404`.
3. **Fehlversuche:** gemeinsamer Eimer (30, 1 pro Sekunde); leer → `429` mit
   `Retry-After`. Gültige Aufrufe belasten ihn nicht.
4. **Auslöser-Rate:** im Schnitt 5 Aufrufe pro Sekunde, Stöße bis 20 (`429`).
5. **Einrichtungsprüfung:** Parameter konfiguriert und vorhanden → `200`
   (`text/plain`, `X-Content-Type-Options: nosniff`) mit dem Wert (höchstens
   2048 Zeichen), **kein** Lauf.
6. **Signatur** bei aktiver Prüfung über die Rohbytes; fehlt Kopfzeile oder
   Geheimnis oder passt sie nicht: `401`.
7. **Lauf starten** wie alle Ereignis-Auslöser (`startEventTriggerRun`):
   sofort `202` ohne Inhalt, Ausführung über den Worker.

Fehlerantworten sind kurz und einheitlich (`{"error": …}`), damit sie nichts
über vorhandene Auslöser verraten. Über 1 MiB: `413`.

## Siehe auch

- [Webhooks: Ausnahme von der Sitzungspflicht](./webhook-sitzungsausnahme.md)
- [Architektur der Webhooks](./webhook-architektur.md)
