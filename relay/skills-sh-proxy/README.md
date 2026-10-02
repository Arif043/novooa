# skills.sh-Proxy

Die skills.sh-API (`https://skills.sh/api/v1`) verlangt für **jeden** Aufruf ein Vercel-OIDC-Token
(600 Anfragen/Minute je Projekt). Dieses Token gibt es nur innerhalb eines Vercel-Projekts. Dieser kleine Proxy
setzt es ein und reicht Status, `X-RateLimit-*`, `Retry-After` und `Cache-Control` unverändert zurück.

## Aufrufweg

```text
Runtime ──(signierte Lizenz)──▶ Firebase-Funktion localRuntimeSkillsRelay ──(HMAC)──▶ dieser Proxy ──(OIDC)──▶ skills.sh
```

- Die **Runtime** kennt weder den Proxy noch ein Geheimnis. Sie schickt ihre signierte Lizenz an die Firebase-Funktion.
- Die **Firebase-Funktion** prüft Lizenz (Signatur, aktiv, Registry) und Anfrage (nur lesende `/skills…`-Pfade und
  bekannte Parameter), begrenzt je Lizenz per Token Bucket (Werte aus Remote Config, siehe
  `docs/features/skills.md`) und signiert den Aufruf des Proxys.
- Dieser **Proxy** akzeptiert nur Aufrufe mit gültiger HMAC-Signatur. Die Signatur gilt über
  `{zeitstempel}\n{METHODE}\n{pfad+query}` (HMAC-SHA256, hex) in den Headern `x-novooa-timestamp` (Unix-ms) und
  `x-novooa-signature`; der Zeitstempel darf höchstens 60 Sekunden abweichen. Das Geheimnis kennen nur Firebase und
  Vercel. Innerhalb des Zeitfensters ist ein abgefangener Aufruf wiederholbar — das ist bei reinen GET-Abfragen
  unkritisch.

## Bereitstellen

1. Vercel-Projekt anlegen, **ohne** Git-Anbindung, aus diesem Ordner:
   ```bash
   cd relay/skills-sh-proxy
   npm install
   npx vercel                      # Git-Repository verbinden? → N
   ```
2. Im Projekt unter *Settings → Security → OIDC Federation* die Föderation aktivieren (sonst gibt es kein
   `VERCEL_OIDC_TOKEN`).
3. Geheimnis erzeugen und in **beiden** Umgebungen setzen (derselbe Wert):
   ```bash
   SECRET=$(openssl rand -hex 32)
   printf %s "$SECRET" | npx vercel env add SKILLS_PROXY_HMAC_KEY production
   printf %s "$SECRET" | firebase functions:secrets:set SKILLS_PROXY_HMAC_KEY
   ```
4. Proxy deployen: `npx vercel --prod`. Die Adresse lautet `https://<projekt>.vercel.app`.
5. Firebase-Funktion mit der Proxy-Adresse deployen (Parameter `SKILLS_PROXY_URL`, z. B. in `functions/.env`):
   ```text
   SKILLS_PROXY_URL=https://<projekt>.vercel.app
   ```
   ```bash
   firebase deploy --only functions:localRuntimeSkillsRelay
   ```

Die Runtime braucht keine Einstellung: `docker-compose.local.yaml` verweist standardmäßig auf die Funktion. Mit
`SKILLS_SH_RELAY_URL=` (leer) ist der Katalog abgeschaltet.

## Entwicklung

```bash
npm test   # Pfadfilter und HMAC-Prüfung inkl. gemeinsamem Testvektor mit der Firebase-Funktion
```

Der Proxy gibt nur lesende Abfragen unter `/api/v1/skills…` weiter; alles andere antwortet mit 400.
