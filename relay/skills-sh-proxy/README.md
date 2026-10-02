# skills.sh-Proxy

Die skills.sh-API (`https://skills.sh/api/v1`) verlangt für **jeden** Aufruf ein Vercel-OIDC-Token
(600 Anfragen/Minute je Projekt). Dieses Token gibt es nur innerhalb eines Vercel-Projekts. Die lokale
Runtime holt es deshalb nicht selbst, sondern fragt diesen kleinen Proxy; er setzt das Token ein und reicht
Status, `X-RateLimit-*`, `Retry-After` und `Cache-Control` unverändert zurück. Das Rate-Limit hält die
Runtime selbst ein (siehe `docs/features/skills.md`).

## Bereitstellen

1. Vercel-Projekt aus diesem Ordner anlegen (`relay/skills-sh-proxy` als Root Directory).
2. Im Projekt unter *Settings → OIDC Federation* die Föderation aktivieren (Voraussetzung für `VERCEL_OIDC_TOKEN`).
3. Umgebungsvariable `SKILLS_PROXY_KEY` setzen: ein langer Zufallswert, der den Zugriff auf den Proxy schützt.
4. Deployen. Die Adresse lautet `https://<projekt>.vercel.app/api/v1`.

## An der Runtime einrichten

In der Umgebung der lokalen Runtime (z. B. `.env` neben `docker-compose.local.yaml`, an den Dienst `runtime`
durchreichen):

```text
SKILLS_SH_BASE_URL=https://<projekt>.vercel.app/api/v1
SKILLS_SH_TOKEN=<Wert von SKILLS_PROXY_KEY>
```

Ohne diese Werte bleibt der Katalog-Tab der App deaktiviert („Der Katalog ist nicht eingerichtet“); der Import
über GitHub, ZIP und Ordner funktioniert unabhängig davon.

## Entwicklung

```bash
npm test   # prüft Pfadfilter und Schlüsselvergleich
```

Der Proxy gibt nur lesende Abfragen unter `/skills…` weiter; alles andere antwortet mit 400.
