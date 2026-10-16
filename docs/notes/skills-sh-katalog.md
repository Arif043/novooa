# skills.sh-Katalog

> Der Katalog läuft über zwei Server-Stufen (Firebase-Relay, Vercel-Proxy), damit bei der Kundschaft kein Geheimnis liegt; er braucht eine aktive Lizenz.

Gehört zu: [Fähigkeiten](../index/faehigkeiten.md)

```text
Runtime ──(signierte Lizenz)──▶ localRuntimeSkillsRelay ──(HMAC)──▶ Vercel-Proxy ──(OIDC)──▶ skills.sh
```

- Adapter für die [skills.sh-API](https://www.skills.sh/docs/api)
  (`/skills`, `/skills/search`, `/skills/curated`, `/skills/{quelle}/{skill}`,
  `/skills/audit/…`). Import über den Detail-Endpunkt, der alle Dateien als
  Text liefert (Binärdateien fehlen; die Vorschau warnt). Die Vorschau zeigt
  die Sicherheitsprüfungen der Partner (Socket, Snyk, …).
- Warum zwei Stufen: Die API verlangt ein Vercel-OIDC-Token für jeden Aufruf.
- **Firebase-Funktion** (`functions/src/features/skills/infrastructure/firebase/`):
  Use Case `RelaySkillsCatalogRequest` prüft Lizenz → Anfrage (nur lesende
  `/skills…`-Pfade, bekannte Parameter, keine `..`/kodierten Trenner) →
  [Token Bucket](./skills-relay-ratenbegrenzung.md) → Upstream. Status und
  Rate-Limit-Header kommen unverändert zurück.
- **Vercel-Proxy** ([`relay/skills-sh-proxy`](../../relay/skills-sh-proxy/README.md))
  prüft die HMAC-Signatur und setzt das OIDC-Token ein.

Runtime-Konfiguration (Vorrang von oben):

| Variable | Bedeutung |
| --- | --- |
| `SKILLS_SH_RELAY_URL` | Firebase-Relay (Normalfall, in Compose voreingestellt; leer = Katalog aus) |
| `SKILLS_SH_BASE_URL` (+ `SKILLS_SH_TOKEN`) | direkte API-Adresse, z. B. Test-Server |
| nur `SKILLS_SH_TOKEN` | direkt gegen `https://skills.sh/api/v1` mit eigenem OIDC-Token (Entwicklung) |

Ohne Lizenz: „Für den Katalog ist eine aktive Lizenz nötig“. Ohne Zugang ist
der Tab deaktiviert; GitHub, ZIP und Ordner gehen trotzdem.

| Route | Zweck |
| --- | --- |
| `GET /v1/skills/catalog/status` | ist ein Katalog eingerichtet? |
| `GET /v1/skills/catalog/search?q=` | Suche (≥ 2 Zeichen) |
| `GET /v1/skills/catalog/browse?view=&page=` | Bestenliste (`all-time`, `trending`, `hot`) |
| `GET /v1/skills/catalog/audits?id=` | Sicherheitsprüfungen |

## Siehe auch

- [Ratenbegrenzung des Skills-Relays](./skills-relay-ratenbegrenzung.md)
- [Rate-Limits des skills.sh-Clients](./skills-sh-client-ratelimits.md)
