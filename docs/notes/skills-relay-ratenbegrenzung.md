# Ratenbegrenzung des Skills-Relays

> Ein Token Bucket je Lizenz verhindert, dass eine Installation das gemeinsame skills.sh-Kontingent (600/min) aufbraucht; ein globaler Eimer ist bewusst nicht vorgesehen.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

| Parameter (Remote Config, Server-Template) | Standard | Bedeutung |
| --- | --- | --- |
| `skills_relay_bucket_capacity` | 20 | Stoß |
| `skills_relay_bucket_refill_per_second` | 0,5 | Dauerrate (30/min) |

- Jede Anfrage kostet ein Token; ein neuer Eimer ist voll. Leer → 429 mit
  `Retry-After = ceil((1 − Token) / Rate)` (meist 1–2 s); der Runtime-Client
  wartet bis 30 s selbst und wiederholt.
- Fehlversuche mit ungültiger Lizenz oder verbotener Anfrage kosten kein
  Token (Lizenz und Anfrage werden vorher geprüft).
- Zustand je Lizenz in Firestore (`skillsRelayRateLimits/{sha256(licenseId)}`,
  Transaktion); eine TTL-Richtlinie auf `expiresAt` (`firestore.indexes.json`)
  räumt auf.
- Warum kein globaler Eimer: Ein gemeinsames Dokument wäre bei etwa einem
  Schreibvorgang pro Sekunde der Engpass. Das globale Limit sichern Cache und
  weitergereichte 429 von skills.sh.
- **Ohne Deploy ändern:** Parameter (Typ Zahl) im Server-Template anlegen und
  veröffentlichen; gelesen höchstens alle 5 Minuten. Fehlend oder ≤ 0 →
  Standard; bei Fehlern der letzte Stand (Neuversuch nach 30 s). Das
  Dienstkonto braucht *Firebase Remote Config Viewer*.
- **HMAC zwischen den Servern:** HMAC-SHA256 über
  `{zeitstempel}\n{METHODE}\n{pfad+query}`, Header `x-novooa-timestamp` /
  `x-novooa-signature`, Fenster ±60 s. Signiert wird die Proxy-URL
  (`/api/relay?p=%2Fskills%2Fsearch&q=…`) — Vercel routet ohne Framework nur
  ein Pfadsegment, deshalb steht der Katalogpfad in `p`. Geheimnis
  `SKILLS_PROXY_HMAC_KEY` kennen nur Firebase und Vercel; beide testen denselben
  Vektor.
- Derselbe Token-Bucket-Algorithmus begrenzt auch
  [Webhooks](./webhook-architektur.md).

## Siehe auch

- [skills.sh-Katalog](./skills-sh-katalog.md)
- [Rate-Limits des skills.sh-Clients](./skills-sh-client-ratelimits.md)
