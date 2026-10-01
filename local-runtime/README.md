# Lokale Runtime

Dieser Ordner enthält Python-Code, Systemmodelle und Build-Skripte für die
Docker-basierte lokale novooa-Runtime.

## Datenbank und Migrationen

Schema und Migrationen der lokalen SQLite-Datenbank liegen nicht hier, sondern
im Functions-Paket:

- Schema (Drizzle-Modelle): `functions/src/db/models/`
- Migrationen: `functions/drizzle/` — aktuell eine zusammengefasste
  Initialmigration `0000_initial_runtime.sql`
- Neue Migration nach einer Modelländerung:
  `npm --prefix functions run db:generate`

Die Runtime führt beim Start den Drizzle-Migrator aus
(`openLocalRuntimeDatabase`). Die Feature-Adapter (z. B. `SQLiteTaskStore`,
`LocalTeamFileStore`, `SQLiteModelCatalog`) arbeiten über `RuntimeDatabase`
(Drizzle auf libsql). Details: [`../docs/local-runtime.md`](../docs/local-runtime.md).

## Python-ONNX-Runtime

Die lokale ONNX-Ausführung und Bildvorverarbeitung laufen im `novooa-ml`
Python-Sidecar. Der Dienst exponiert nur im privaten Compose-Netz die
Endpunkte `/v1/models`, `/v1/inferences` und `/v1/input-transforms`.

Für Python-Tests außerhalb von Docker kann eine virtuelle Umgebung verwendet
werden:

```bash
python3 -m venv .novooa/python
.novooa/python/bin/python -m pip install -r local-runtime/python/requirements.txt
```

Die Node-Runtime verbindet sich mit diesem Sidecar über `novooa-private`. Sie
enthält einen minimalen Python-Interpreter für isolierte Script-Bausteine,
jedoch keine Python-ML-Abhängigkeiten.


## Clients im LAN und öffentlich

Der Compose-Stack veröffentlicht den Runtime-Port `8090` auf allen
Schnittstellen — auch das erstmalige Setzen des Betreiber-Passworts läuft
darüber; der Python-Sidecar bleibt im privaten Docker-Netz. Clients im LAN geben die
private IPv4-Adresse des Hosts ein und verbinden sich unverschlüsselt über
HTTP.

novooa terminiert selbst kein TLS. Wer die Runtime aus dem Internet
erreichbar machen will, stellt einen eigenen Reverse Proxy mit Domain und
Zertifikat davor — der Client erkennt eine Domain und verwendet dann HTTPS.
Port `8090` darf dabei nicht direkt öffentlich erreichbar sein, sonst gehen
Passwort und Session-Token im Klartext übers Internet. Jede Verbindung
verlangt zusätzlich ein selbst gewähltes Betreiber-Passwort — siehe
[`docs/local-runtime.md`](../docs/local-runtime.md#zugriff-und-authentifizierung)
für das einmalige Setzen des Passworts, den Login-Ablauf und ein
nginx-Beispiel.

Die Runtime richtet von sich aus keine Portweiterleitungen ein; ob der Host
aus anderen Netzen erreichbar ist, bestimmen ansonsten Router und Firewall
des Kunden.

## Lokaler Stack

```bash
npm --prefix functions run local-runtime:prepare -- \
  --secret-file ../.novooa/runtime-master-key
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
```

Das Volume `novooa-data` enthält SQLite und lokale Dateien. `novooa-ml` erhält
weder dieses Volume noch einen veröffentlichten Host-Port.

Der erste Befehl erzeugt einmalig einen zufälligen 32-Byte-Master-Key. Compose
mountet ihn ausschließlich für `runtime` als Datei unter `/run/secrets`. Der
Key ist absichtlich nicht Teil des Daten-Volumes und darf weder eingecheckt noch
gelöscht werden, solange verschlüsselte Provider-Zugänge wiederherstellbar sein
sollen.

## Images für einen Ziel-Rechner bauen

`build-images.sh` baut die beiden Runtime-Images (`novooa-runtime`,
`novooa-ml`) eigenständig auf diesem Rechner für `linux/amd64` — unabhängig
von der eigenen Host-Architektur (Cross-Compile via Docker Buildx/QEMU) und
ohne SSH oder eine Deployment-CLI. Das Ergebnis ist eine einzelne `.tar`-Datei
mit beiden Images, die auf jedem Docker-Host ohne Registry-Zugriff eingespielt
werden kann:

```bash
./local-runtime/build-images.sh 0.1.0
```

Ergebnis:

```text
local-runtime/build/novooa-images-0.1.0.tar
```

Auf dem Ziel-Rechner (z.B. dem Windows-Host, der `docker-compose.local.yaml`
betreibt):

```powershell
docker load -i novooa-images-0.1.0.tar
```

Anschließend referenziert eine Compose-Datei die geladenen Images per
`image: novooa-runtime:0.1.0` / `image: novooa-ml:0.1.0` statt sie per
`build:` aus dem Quellcode zu bauen — genau das, was
[`deployment.md`](../docs/deployment.md) für auslieferbare, versionierte
Images fordert ("niemals `latest`, immer eine konkrete Version").

Voraussetzung ist ein Buildx-Builder mit `linux/amd64`-Unterstützung
(`docker buildx ls` zeigt die verfügbaren Plattformen je Builder). Docker
Desktop und OrbStack bringen das standardmäßig mit.
