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
  `{zeitstempel}\n{METHODE}\n{pfad+query}` (HMAC-SHA256, hex) — genau die Anfrage-URL, wie Vercel sie sieht, also
  `/api/relay?p=%2Fskills%2Fsearch&q=react` — in den Headern `x-novooa-timestamp` (Unix-ms) und
  `x-novooa-signature`; der Zeitstempel darf höchstens 60 Sekunden abweichen. Das Geheimnis kennen nur Firebase und
  Vercel. Innerhalb des Zeitfensters ist ein abgefangener Aufruf wiederholbar — das ist bei reinen GET-Abfragen
  unkritisch.

## Bereitstellen

1. Vercel-Projekt anlegen, **ohne** Git-Anbindung, aus diesem Ordner (nur die erste Verknüpfung; deployt wird mit Schritt 4):
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
4. Proxy deployen. Weil Vercel das Git-Repository der Umgebung (`syscat2`) samt Autor-E-Mail des letzten Commits
   mitschickt und auf dem Hobby-Tarif blockt, wenn die E-Mail keinem Teammitglied gehört, deployt man aus einer Kopie
   **ohne** Git-Bezug:
   ```bash
   rsync -a --exclude node_modules --exclude .git relay/skills-sh-proxy/ /tmp/skills-sh-proxy-deploy/
   cd /tmp/skills-sh-proxy-deploy && npx vercel --prod --yes
   ```
   (Das Verzeichnis `.vercel/` mit der Projektverknüpfung wird mitkopiert.) *Deployment Protection → Vercel
   Authentication* muss für Production aus sein, sonst erreicht die Firebase-Funktion den Proxy nicht.
5. Schnelltest: Ohne Signatur antwortet der Proxy mit 401.
   ```bash
   curl -i "https://<projekt>.vercel.app/api/relay?p=%2Fskills%2Fsearch&q=react"
   ```
   Mit gültiger Signatur (Zeitstempel in Millisekunden):
   ```bash
   SECRET=<dein Wert>; TS=$(($(date +%s)*1000)); P="/api/relay?p=%2Fskills%2Fsearch&q=react"
   SIG=$(printf "%s\nGET\n%s" "$TS" "$P" | openssl dgst -sha256 -hmac "$SECRET" -hex | awk '{print $NF}')
   curl -i -H "x-novooa-timestamp: $TS" -H "x-novooa-signature: $SIG" "https://<projekt>.vercel.app$P"
   ```
6. Firebase-Funktion mit der Proxy-Adresse deployen (Parameter `SKILLS_PROXY_URL`, z. B. in `functions/.env`):
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

Der Proxy hat genau eine Adresse, `/api/relay`; der Katalogpfad steht im Parameter `p`. Er gibt nur lesende Abfragen
unter `/skills…` weiter, alles andere antwortet mit 400.
