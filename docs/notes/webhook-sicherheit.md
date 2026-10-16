# Sicherheit und Grenzen der Webhooks

> Der Endpunkt ist öffentlich und nur durch Token und Begrenzungen geschützt; wo möglich gehört die Signaturprüfung eingeschaltet.

Gehört zu: [Webhooks](../index/webhooks.md)

- **Öffentlich:** Token (256 Bit) und Begrenzungen schützen. Die Adresse steht
  in Zugriffsprotokollen eines Reverse Proxys — deshalb Signatur einschalten.
- **Keine IP-Begrenzung:** Hinter einem Proxy sähen alle gleich aus
  (`trustProxy` nicht gesetzt); daher ein gemeinsamer Eimer für Fehlversuche.
- **Keine Wiederholungs- und Duplikaterkennung:** Ein wiederholter oder
  abgefangener Aufruf mit gültiger Signatur startet einen weiteren Lauf; keine
  Zeitstempelprüfung.
- **Untrusted Input:** Fließt der Inhalt in einen Prompt, ist Prompt-Injection
  möglich; dagegen gibt es keine technische Maßnahme.
- Der Inhalt wird mit dem Lauf gespeichert (bis 1 MiB) und erscheint im
  Aktivitätsprotokoll.
- Nur bei laufender Runtime und aktiver Lizenz; verpasste Aufrufe holt niemand
  nach.

## Siehe auch

- [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md)
- [Webhook-Auslöser](./webhook-ausloeser.md)
