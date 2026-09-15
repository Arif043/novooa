# Lokale Runtime

Dieser Ordner enthält Migrationen und Python-Code für die Docker-basierte
lokale novooa-Runtime.

## Migrationen

Migrationen liegen unter `migrations/` und werden in aufsteigender Reihenfolge
ausgeführt. Die Migrationen bilden die bestehenden Cloud-Konzepte lokal ab:

- Teams und Mitglieder
- Aufgaben und TaskRuns
- Aktivitäten
- Zeit- und Event-Trigger
- Kommunikationskanäle
- Wissensbasis
- Dateien und Dateiversionen

`004_model_catalog.sql` ergänzt den ML-Modellkatalog und ONNX-Modellverträge.
`006_task_run_jobs.sql` ergänzt die persistente Jobqueue für lokale Runs.

Die Cloud Functions nutzen diese Dateien noch nicht direkt. Sie dienen als
Vertrag für die späteren SQLite-Adapter:

- `SQLiteTaskStore`
- `SQLiteTaskRunStore`
- `SQLiteActivityStore`
- `SQLiteTaskTriggerStore`
- `LocalTeamFileStore`
- `SQLiteKnowledgeBaseStore`
- `SQLiteModelCatalog`
- `LocalModelArtifactReader`
- `SQLiteTaskRunJobStore`
- `HttpPythonModelInputTransformer`
- `SidecarOnnxInferenceRuntime`

`SqliteLocalSqlDatabase` verwendet Node 24 `node:sqlite`. Die Feature-Adapter
bleiben über `LocalSqlDatabase` an die Datenbank gebunden und nicht an diesen
konkreten Treiber.

Migrationen werden über `SqlMigrationRunner` angewendet. Der Runner erwartet
bereits aufbereitete Statements; ein lokaler CLI kann die Dateien aus
`migrations/` lesen und mit `migrationFromSqlFile` in Migrationen umwandeln.

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

Die Node-Runtime verbindet sich mit diesem Sidecar über `novooa-private`; sie
enthält weder einen Python-Interpreter noch Python-Abhängigkeiten.


## Clients im LAN

Der Compose-Stack veröffentlicht ausschließlich den Runtime-Port `8090`; der
Python-Sidecar bleibt im privaten Docker-Netz. Auf dem Host verbindet sich der
native Client automatisch mit `127.0.0.1`. Ein weiterer nativer Client im selben
LAN gibt nur die private IPv4-Adresse des Runtime-Hosts ein, zum Beispiel
`192.168.1.42`. Die Adresse wird als normale App-Einstellung gespeichert und vor
der Verwendung über `GET /healthz` geprüft.

Die Runtime richtet weder Portweiterleitungen noch externen Fernzugriff ein. Ob
der Host aus anderen Netzen erreichbar ist, bestimmen Router und Firewall des
Kunden.

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
