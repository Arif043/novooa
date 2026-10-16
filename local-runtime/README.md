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
(Drizzle auf libsql). Details: [`docs/index/lokale-runtime.md`](../docs/index/lokale-runtime.md).

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
enthält kein Python. Script-Bausteine laufen im eigenen, abgeschotteten Container `novooa-script`
(internes Netz `novooa-script`, siehe
[Script-Dienst: Schnittstelle](../docs/notes/script-dienst-schnittstelle.md)).
Seine Tests: `docker run --rm -v "$PWD/local-runtime/python:/app/python" -w /app/python python:3.12-slim python -m unittest tests.test_script_service`.


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
[Betreiber-Passwort-Pflicht](../docs/notes/betreiber-passwort-pflicht.md)
für das einmalige Setzen des Passworts, den Login-Ablauf und ein
nginx-Beispiel.

Die Runtime richtet von sich aus keine Portweiterleitungen ein; ob der Host
aus anderen Netzen erreichbar ist, bestimmen ansonsten Router und Firewall
des Kunden.

## Lokaler Stack

```bash
docker compose -f docker-compose.server.yaml up --build --detach   # einmal pro Rechner: ML-Dienst
docker compose -f docker-compose.local.yaml up --build --detach    # der Stack
curl http://127.0.0.1:8090/healthz
```

Dasselbe als npm-Skripte: `npm --prefix functions run local-runtime:docker:deploy`
startet bzw. aktualisiert den ML-Dienst, baut den Stack neu und wartet, bis die
Runtime antwortet. `ml:docker:tenants` listet die angemeldeten Runtimes,
`ml:docker:logs` zeigt das Log des ML-Dienstes, `local-runtime:docker:down-all`
stoppt beides (erst den Stack, sonst ist das Netz `novooa-ml` noch belegt).

Das Volume `novooa-data` enthält SQLite und lokale Dateien. Der ML-Dienst
(`docker-compose.server.yaml`) erhält weder dieses Volume noch einen
veröffentlichten Host-Port; alle Stacks des Rechners teilen ihn. Katalogmodelle lädt
er aus dem globalen Modellspeicher (`NOVOOA_MODEL_STORE_URL`, öffentlich lesbar),
Teammodelle streamt ihm die Runtime. Jede Runtime meldet sich mit ihrer
Lizenz-ID an; `docker compose -f docker-compose.server.yaml exec
novooa-ml python -m novooa_ml.tenants list` zeigt die angemeldeten Runtimes.

### Mehrere Stacks auf einem Rechner

Jeder Stack bekommt einen eigenen Projektnamen und Port; über den Projektnamen
erhält er eigene Volumes, also eigene Daten und einen eigenen Master-Key. Jeder
Stack braucht eine eigene Lizenz.

```bash
# kunden/a.env (ersetzt die .env im Projektordner)
NOVOOA_RUNTIME_PORT=8091

docker compose -p kunde-a --env-file kunden/a.env -f docker-compose.local.yaml up --build --detach
```

Docker vergibt Netze aus einem begrenzten Adresspool (etwa 30 Netze); jeder Stack
braucht drei. Für mehr als etwa zehn Stacks den Pool in `/etc/docker/daemon.json`
vergrößern und Docker neu starten:

```json
{"default-address-pools": [{"base": "10.200.0.0/16", "size": 24}]}
```

Das Shopware-Testsystem startet nur mit `--profile dev`.

Den Master-Key erzeugt beim ersten Start der Init-Dienst `key-init` im Volume
`novooa-keys`; danach rotiert ihn die Runtime selbst. Er ist absichtlich nicht
Teil des Daten-Volumes. Ein Backup braucht `novooa-data` **und** `novooa-keys`,
sonst sind die verschlüsselten Provider-Zugänge verloren. Den öffentlichen
Lizenzschlüssel bringt das Image mit (`functions/keys`); auf dem Server liegen
keine Schlüsseldateien.

## Images für einen Ziel-Rechner bauen

`build-images.sh` baut die drei Runtime-Images (`novooa-runtime`,
`novooa-ml`, `novooa-script`) eigenständig auf diesem Rechner für `linux/amd64` — unabhängig
von der eigenen Host-Architektur (Cross-Compile via Docker Buildx/QEMU) und
ohne SSH oder eine Deployment-CLI. Das Ergebnis ist eine einzelne `.tar`-Datei
mit allen Images, die auf jedem Docker-Host ohne Registry-Zugriff eingespielt
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
`image: novooa-runtime:0.1.0` / `image: novooa-ml:0.1.0` /
`image: novooa-script:0.1.0` statt sie per
`build:` aus dem Quellcode zu bauen — genau das, was
[`deployment.md`](../docs/deployment.md) für auslieferbare, versionierte
Images fordert ("niemals `latest`, immer eine konkrete Version").

Voraussetzung ist ein Buildx-Builder mit `linux/amd64`-Unterstützung
(`docker buildx ls` zeigt die verfügbaren Plattformen je Builder). Docker
Desktop und OrbStack bringen das standardmäßig mit.
