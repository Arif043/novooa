# Deployment mit Coolify

> Coolify zieht fertige, gehärtete Images aus GHCR; ein gemeinsamer ML-Dienst und getrennte Kunden-Stacks laufen im Raw-Compose-Modus mit eigenen Netzen.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md) · [Lokale Runtime](../index/lokale-runtime.md)

## Ressourcen

Zwei Git-Anwendungen auf demselben Server, beide mit Docker-Compose-Build-Pack,
Basisverzeichnis `/` und **Raw (deploy file as-is)**. Die Compose-Dateien unter
`deploy/coolify/` ziehen fertige, gehärtete Images aus der privaten GitHub
Container Registry; Coolify baut nichts aus dem Quellcode.

| Anwendung | Compose-Datei | Öffentlicher Zugriff |
| --- | --- | --- |
| ML-Server, einmal pro Server | `/deploy/coolify/novooa-ml.yaml` | keiner |
| Runtime, einmal pro Kunde | `/deploy/coolify/novooa-customer.yaml` | HTTPS über Traefik |

**Nicht** als eingefügte Compose („Docker Compose Empty“) anlegen: Coolify hängt
dort jeden Dienst an alle Netze der Datei (`serviceParser`); der Script-Dienst
käme so ins Proxy-Netz und damit ins Internet. Coolify lehnt außerdem
verschachtelte Variablen in Netznamen ab (`${A:-${B}}`); die Dateien unter
`deploy/coolify/` verwenden deshalb nur einfache Standardwerte.

## Images

`ghcr.io/arif043/novooa-runtime`, `novooa-script`, `novooa-packages` und
`novooa-ml`, Tag `<Datum>-<Commit>`, nie `latest`. Gebaut werden sie für
`linux/amd64` aus einem sauberen Commit:

```bash
T=2026.10.31-0e3e108e; R=ghcr.io/arif043
docker buildx build --platform linux/amd64 -f functions/Dockerfile.local-runtime --target web-runtime -t $R/novooa-runtime:$T --push .
docker buildx build --platform linux/amd64 -f functions/Dockerfile.script-runner -t $R/novooa-script:$T --push .
docker buildx build --platform linux/amd64 -f functions/Dockerfile.script-packages -t $R/novooa-packages:$T --push .
docker buildx build --platform linux/amd64 -f functions/Dockerfile.model-inference-sidecar -t $R/novooa-ml:$T --push .
```

Der Standard-Tag steht in beiden Compose-Dateien; `NOVOOA_VERSION` überschreibt
ihn für ein Update. Die Runtime-Image dient auch für Schlüssel-Init und
-Rotation. Vor dem Push den Smoke-Test aus
[Quellcode-Schutz](./runtime-quellcode-schutz.md) gegen das Runtime-Image laufen
lassen.

## Reihenfolge

1. In Coolify unter Server oder Projekt die Registry `ghcr.io` mit einem
   GitHub-Token (`read:packages`) hinterlegen; die Pakete sind privat.
2. ML-Anwendung zuerst deployen. Sie erzeugt das interne Netz `novooa-ml`.
   `NOVOOA_MODEL_STORE_URL` auf den [Modellspeicher](./modellspeicher-garage.md)
   setzen; Speicher- und CPU-Grenzen der Serverkapazität anpassen.
3. Kunden-Anwendung mit `deploy/coolify/novooa-customer.yaml` anlegen und die
   untenstehenden Umgebungsvariablen setzen. Keine zusätzlichen
   Coolify-Domains oder Proxy-Labels generieren.
4. Falls abweichend: `COOLIFY_CERTIFICATE_RESOLVER` (Standard `letsencrypt`) setzen.
   Traefiks EntryPoints müssen `http` und `https` heißen.
5. DNS der Domain auf den Server richten. Deployen und HTTPS sowie
   `/healthz`, Web-App und geschützte API-Routen prüfen.
6. Lizenz aktivieren und das erste Admin-Konto über die
   [Ersteinrichtung](./runtime-ersteinrichtung.md) anlegen.

## Umgebungsvariablen der Kunden-Anwendung

```dotenv
NOVOOA_INSTANCE=erkan
NOVOOA_DOMAIN=erkan.novooa.cloud
```

`NOVOOA_INSTANCE` muss je Kunde eindeutig sein und stabil bleiben: Daraus
entstehen Compose-Projekt, Volume-Namen und Traefik-Router. Optional:
`NOVOOA_VERSION` (anderer Image-Tag), `COOLIFY_PROXY_NETWORK` (Standard
`coolify`), `NOVOOA_RUNTIME_BIND_ADDRESS` und `NOVOOA_RUNTIME_PORT`
(Standard `127.0.0.1` und `0`, also ein freier Port nur auf dem Server).
Traefik erreicht die Runtime direkt im Container auf Port `8080`.

Lokal und auf eigenen Rechnern gilt weiter `docker-compose.local.yaml`, das
aus dem Checkout baut.

## Daten

Der Init-Dienst erzeugt den Master-Key im Volume, läuft ohne Netz und endet
erfolgreich. In Coolify diesen Einmaldienst von der aggregierten
Statusprüfung ausschließen, falls er sonst als beendet angezeigt wird.
Die Runtime startet erst danach.

- `novooa-data`: SQLite, Dateien und Arbeitsbereichsdaten.
- `novooa-keys`: Schlüsselbund; zusammen mit den Daten sichern.
- `novooa-script-packages`: installierte Python-Paketumgebungen des Kunden.
- `novooa-ml-data`: Modelle und Mandantenregistrierungen des ML-Servers.

Es gibt keine öffentlichen Host-Port-Freigaben und keine lokalen Web-Bind-Mounts.
Nur die Runtime hängt am Proxy-Netz; Script- und Paketdienst bleiben davon
getrennt. Der ML-Server behält sein gemeinsames internes Netz.

## Siehe auch

- [Docker-Stack der Runtime](./runtime-docker-stack.md)
- [Quellcode-Schutz der Images](./runtime-quellcode-schutz.md)
- [Reverse Proxy für externen Zugriff](./reverse-proxy-externer-zugriff.md)
- [Coolify: Docker Compose](https://coolify.io/docs/applications/builds/docker-compose)
