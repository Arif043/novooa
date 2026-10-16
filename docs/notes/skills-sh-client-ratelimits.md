# Rate-Limits des skills.sh-Clients

> `SkillsShClient` hält die Limits von skills.sh ein, statt sie auszureizen: Header beachten, Retry-After befolgen, cachen und gleiche Anfragen bündeln.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

- Merkt sich `X-RateLimit-Remaining/Reset`; ist das Kontingent erschöpft,
  wartet er bis zum Reset (höchstens 30 s) oder meldet „Zu viele Anfragen … in
  N Sekunden“ (429 mit `Retry-After` an die App).
- Befolgt `Retry-After` bei 429 (höchstens 2 Wiederholungen), wiederholt 503
  mit Backoff (1 s, 2 s).
- Cacht nach `Cache-Control` (Standard 60 s Suche/Liste, 300 s Detail) und
  fasst gleiche gleichzeitige Anfragen zusammen.
- Ein gemeinsamer Client für Suche, Bestenliste und Import — Limit und Cache
  gelten gemeinsam.
- Die App entprellt die Suche (400 ms) und sendet erst ab zwei Zeichen.

## Siehe auch

- [Ratenbegrenzung des Skills-Relays](./skills-relay-ratenbegrenzung.md)
