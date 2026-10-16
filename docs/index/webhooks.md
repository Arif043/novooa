# Webhooks

> Externe Systeme starten Aufgaben, indem sie eine Adresse der Runtime aufrufen; das ist die eingehende Hälfte der Schicht für externe Systeme (Standalone).

- [Webhook-Auslöser](../notes/webhook-ausloeser.md)
- [Ablauf eines Webhook-Aufrufs](../notes/webhook-aufruf.md)
- [Webhook-Ereignis im Lauf](../notes/webhook-ereignis.md)
- [Architektur der Webhooks](../notes/webhook-architektur.md)
- [Webhooks: Ausnahme von der Sitzungspflicht](../notes/webhook-sitzungsausnahme.md)
- [Sicherheit und Grenzen der Webhooks](../notes/webhook-sicherheit.md)

## Offene Punkte

- Abonnements bei Absendern verwalten (z. B. Graph-Subscriptions).
- Adapter für bestimmte Systeme; Einrichtungsprüfung und HMAC sind allgemein.
- Konfigurierbare öffentliche Basis-Adresse (z. B. `NOVOOA_PUBLIC_URL`).
- Geheimnis oder Prüfung eines vorhandenen Auslösers ändern.
- Idempotenz, Zeitstempelprüfung, andere Signaturarten, Inhaltsfilter.
- Der KI-Agent kennt den Baustein „Webhook-Ereignis“ nicht.

## Verwandt

- [Verbindungen](./verbindungen.md) — ausgehende Hälfte
- [Integrationen](./integrationen.md)
- [Zeitplan](./zeitplan.md)
- [Lokale Runtime](./lokale-runtime.md)
