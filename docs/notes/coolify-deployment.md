# Deployment mit Coolify

> Coolify baut die Web-App im Runtime-Image; ein gemeinsamer ML-Dienst und getrennte Kunden-Stacks erhalten ihre expliziten Netze im Raw-Compose-Modus.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md) · [Lokale Runtime](../index/lokale-runtime.md)

## Ressourcen

Zwei Git-Anwendungen auf demselben Server, jeweils mit Docker-Compose-Build
und Basisverzeichnis `/`:

| Anwendung | Compose-Datei | Öffentlicher Zugriff |
| --- | --- | --- |
| ML-Server, einmal pro Server | `/docker-compose.server.yaml` | keiner |
| Runtime, einmal pro Kunde | `/docker-compose.local.yaml` | HTTPS über Traefik |

Beide Anwendungen verwenden **Raw (deploy file as-is)**. Coolifys normale
Compose-Verarbeitung ergänzt weitere Netzverbindungen; das würde die
Abschottung des Script-Dienstes aufheben. Die Compose-Dateien übernehmen
deshalb Netze, Volumes, Healthchecks und Proxy-Labels selbst.

## Reihenfolge

1. Repository-Zugang und Branch `main` auswählen; private Quelle über eine
   bereits eingerichtete GitHub-App oder einen lesenden Deploy-Key verbinden.
2. ML-Anwendung zuerst deployen. Sie erzeugt das interne Netz `novooa-ml`.
   `NOVOOA_MODEL_STORE_URL` auf den [Modellspeicher](./modellspeicher-garage.md)
   setzen; Speicher- und CPU-Grenzen der Serverkapazität anpassen.
3. Kunden-Anwendung mit `docker-compose.local.yaml` anlegen und die
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
NOVOOA_PROXY_ENABLED=true
COOLIFY_PROXY_NETWORK=coolify
NOVOOA_RUNTIME_BIND_ADDRESS=127.0.0.1
NOVOOA_RUNTIME_PORT=0
```

`NOVOOA_INSTANCE` muss je Kunde eindeutig sein und stabil bleiben: Daraus
entstehen Compose-Projekt, Volume-Namen und Traefik-Router. Der aktivierte
Proxy verwendet das bestehende externe Coolify-Netz. Port `0` lässt Docker
einen freien Host-Port wählen; die Bind-Adresse beschränkt ihn auf den
Server. Traefik erreicht die Runtime direkt im Container auf Port `8080`.

Ohne diese Variablen bleibt die Compose lokal unter Port `8090` erreichbar;
Traefik ist deaktiviert und das öffentliche Netz gehört zum lokalen Stack.

## Build und Daten

Das Ziel `web-runtime` in `functions/Dockerfile.local-runtime` baut mit
Flutter `3.47.5` (über `FLUTTER_VERSION` überschreibbar), dem eingecheckten
Lockfile und `--release --no-source-maps`. Mitgelieferte Source-Maps aus
Paket-Assets werden danach ebenfalls entfernt. Es liefert Web-App und API unter
derselben Herkunft; `WORKSPACE_API_URL` bleibt beim Web-Build leer.
Die gemeinsame Compose verwendet `web-runtime`; das API-only-Ziel `runtime`
bleibt für Schlüssel-Kommandos und Builds ohne Web-App verfügbar.

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
