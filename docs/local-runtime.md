# Lokale Runtime

## Ziel

novooa soll später vollständig lokal laufen können: Aufgaben, Ausführungen,
Aktivitäten, Dateien, Wissensbasis und Trigger-Zustand liegen lokal. Cloud-
Provider wie Twilio bleiben optional über einen dünnen novooa-Relay nutzbar.

## Runtime-Schichten

```text
Feature Domain
  Entities, Repository-Ports und Use Cases

Feature Infrastructure
  Task Runner und Node Executors
  Firebase-, Genkit- und Twilio-Adapter
  Lokale SQLite- und Dateisystem-Adapter
  Callable-, Scheduler- und Webhook-Handler
```

## Deployment

Die lokale Variante wird über Docker Compose betrieben. Docker Desktop ist
auf macOS und Windows eine explizite Voraussetzung; auf Linux wird eine
kompatible Docker Engine benötigt. novooa bündelt Docker nicht und startet
keine Container Engine selbst.

Die Flutter-Desktop-App ist der lokale Client und verbindet sich nur mit dem
lokalen Runtime-Endpunkt. Sie verwaltet keine SQLite-Dateien oder Docker-Volumes
direkt. Das automatische Prüfen, Starten und Überwachen des versionierten
Compose-Stacks gehört zur auslieferbaren Desktop-App und ist noch nicht
implementiert.

```text
Flutter-Desktop-App
  -> Docker Desktop / Docker Engine
      -> novooa-runtime (Node)
          lokale API, Scheduler, Task-Worker, SQLite-Adapter, Relay-Client
      -> novooa-ml (Python)
          Tensor-Transformationen und ONNX-Inferenz
```

`novooa-runtime` ist der einzige Dienst mit einem veröffentlichten Host-Port.
Compose bindet ihn ausschließlich an `127.0.0.1`; die konkrete Portzuordnung
konfiguriert die Desktop-App für die jeweilige Installation. `novooa-ml` ist
nicht vom Host erreichbar und kommuniziert nur über das interne
Compose-Netzwerk mit `novooa-runtime`.

Das benannte Volume `novooa-data` enthält SQLite, Dateien, Wissensbasis und
lokale Modellartefakte. Es ist nur in `novooa-runtime` schreibbar eingehängt.
Der Python-Dienst erhält keine Datenbank und kein schreibbares Daten-Volume;
er verarbeitet ausschließlich geprüfte Modellbytes und Tensoren über sein
Protokoll. Container erhalten weder den Docker-Socket noch Docker-Credentials.

Das aktuelle Entwicklungs-Compose baut die Images aus dem Checkout. Die
auslieferbare Desktop-App wird stattdessen Images auf konkrete novooa-Versionen
referenzieren, niemals auf `latest`. Vor einem Update muss `novooa-runtime`
ein SQLite-Backup anlegen. Ausschließlich die Runtime führt idempotente
Migrationen aus und meldet ihren Health-Status. Für Runtime und ML-Dienst gilt
`restart: unless-stopped`, damit Zeitpläne und gepufferte Relay-Ereignisse auch
ohne geöffnete Desktop-App verarbeitet werden.

Lokale Secrets bleiben außerhalb des Daten-Volumes. Die Desktop-App löst sie
über den lokalen Secret Store auf und stellt der Runtime nur die benötigten
Werte über einen schreibgeschützten, installationsspezifischen Mount bereit.
Die Runtime darf ausgehend den novooa-Relay und konfigurierte Modellprovider
erreichen; der ML-Dienst erhält keinen direkten Internetzugang.

## Lokale Datenhaltung

SQLite ist der Default für strukturierte lokale Daten. Es braucht keinen Server,
ist transaktional und eignet sich für Aufgaben, Runs, Aktivitäten, Trigger,
Teams, Kanäle, Wissensbasis-Metadaten und Modellkataloge.

Die erste Migration liegt in
[`local-runtime/migrations/001_initial.sql`](../local-runtime/migrations/001_initial.sql).
Sie legt diese Tabellen an:

```text
teams
team_members
tasks
task_runs
activities
task_triggers
communication_channels
knowledge_notes
files
file_versions
file_folders
```

Die Migration
[`004_model_catalog.sql`](../local-runtime/migrations/004_model_catalog.sql)
ergänzt den ONNX-Modellkatalog in der Tabelle `model_catalog`.

[`005_language_models.sql`](../local-runtime/migrations/005_language_models.sql)
ergänzt Provider-Verbindungen und Sprachmodellprofile. Lokale API-Keys liegen
nicht in SQLite, sondern in einem lokalen Secret Store; `secret_ref` verweist
auf den jeweiligen Eintrag.

Dateien liegen im lokalen Dateisystem:

```text
.novooa/
  files/{teamId}/{fileId}/versions/{versionId}/{fileName}
  model-artifacts/{artifactId}/versions/{versionId}/model.onnx
  knowledge/{teamId}/...
```

ONNX-Inferenz läuft lokal im dedizierten Python-Sidecar. Dieser erhält keine
Speicherpfade, sondern verifizierte Modellbytes und Tensoren über das
standardisierte HTTP-Protokoll. Die Abhängigkeiten liegen in
[`local-runtime/python/requirements.txt`](../local-runtime/python/requirements.txt);
die Compose-Definition startet daraus den `novooa-ml`-Container. Der
Node-Container enthält keinen Python-Interpreter und keine ML-Abhängigkeiten.

Workflow-Werte werden vor der lokalen Inferenz gemäß Modellvertrag in Tensoren
transformiert. `input_transform_worker.py` verwendet für Bildquellen eine
erweiterbare Registry für Dekodierung, Skalierung, Layout und Normalisierung.
Weitere Quelltypen erhalten eigene Strategien; weder die Pipeline noch der
Modell-Baustein sind an Firebase Storage oder Bilder gekoppelt.

## Lokale Identität und Teams

Firebase Auth ist für eine rein lokale Runtime nicht erforderlich. Beim ersten
Start wird ein lokaler Nutzer und ein lokales Team erzeugt. Das Team-Feature
bleibt erhalten, wird lokal aber über `teams` und `team_members` abgebildet.
Ein späterer Cloud-Login kann zusätzlich für Sync, Migration oder Relay-Zugriff
verwendet werden.

## Twilio und externe Trigger

Twilio wird nicht direkt auf jede lokale Installation zeigen. Stattdessen nutzt
die lokale Runtime einen novooa Cloud Relay:

```text
Twilio
→ novooa Cloud Relay
→ lokale novooa Runtime
→ SQLite task_runs
→ lokaler Worker
```

Ausgehende Nachrichten laufen umgekehrt:

```text
lokale novooa Runtime
→ novooa Cloud Relay
→ Twilio
```

Der Relay verwaltet Twilio-Credentials und Subaccounts zentral. Die lokale
Runtime authentifiziert sich beim Relay über ein Geräte-/Workspace-Token. Wenn
die lokale Runtime offline ist, kann der Relay Events puffern und später
zustellen.

## Aktueller Implementierungsstand

Die Runtime folgt vollständig der Feature-First-Struktur aus
[`backend-struktur.md`](./backend-struktur.md). Ports und Use Cases liegen im
Domain-Bereich ihres Features; Cloud- und Local-Adapter bleiben austauschbar in
dessen Infrastructure-Bereich.

- `task_execution` enthält Task Runner, Node Executors und Ports für
  Definitionen, Runs, Aktivitäten und ausgehende Nachrichten.
- `teams`, `scheduling`, `communication`, `files`, `knowledge_base` und
  `notifications` kapseln jeweils ihre eigenen Domain-Verträge und Adapter.
- Task-Ausführung erhält Dateien, Wissensbasis und Nachrichten ausschließlich
  über injizierte Ports; Function-Handler verdrahten die konkreten Adapter.
- Lokale SQL-Adapter für Tasks, Runs, Aktivitäten, Trigger, Wissensbasis und
  Dateiordner hängen nur an `LocalSqlDatabase`.
- Alle Backend-Assistenten verwenden denselben `GenkitAssistantResponder` und
  denselben Laufzeitkontext für Cloud und lokal. Ein lokaler Composition Root
  kann den Wissensbasis-Agenten mit `SQLiteKnowledgeBaseAssistantNoteStore`,
  `SQLiteTeamContextStore` und dem öffentlichen HTTP/HTML-Adapter verdrahten;
  der TaskBuilder-Agent benötigt außer Modell und Prompt keinen Fachadapter.
  Firebase verwendet für den Wissensbasis-Adapter Firestore und Firebase Auth.
- `LocalTeamFileStore` schreibt Dateien in ein lokales Root-Verzeichnis und
  persistiert Datei-/Versions-Metadaten über `LocalSqlDatabase`.
- `LocalOnnxInferenceRuntime` und `LocalPythonOnnxWorker` führen ONNX-Modelle
  über `local-runtime/python/onnx_worker.py` aus. Der gemeinsame
  `ModelInferenceRuntime`-Port hält diese lokale Ausführung von einer späteren
  Cloud-Runtime entkoppelt.
- `PrepareModelInputs` und `LocalPythonModelInputTransformer` bereiten
  vertragsbasierte Quellen als Tensoren auf. Bild- und unveränderte
  Tensorquellen sind bereits implementiert; weitere Quelltypen folgen als
  Strategien. Die Cloud erhält später einen alternativen Adapter für denselben
  `ModelInputTransformer`-Port.
- `SqlMigrationRunner` wendet Migrationen treiberneutral über
  `LocalSqlDatabase` an.
- `SqliteLocalSqlDatabase` verwendet die Node-24-Standardbibliothek
  `node:sqlite`, aktiviert Fremdschlüssel, WAL und einen Busy-Timeout. Es
  serialisiert lokale Datenbankzugriffe und normalisiert Zeilen in gewöhnliche
  Records für die lokalen Adapter.
- `openLocalRuntimeDatabase` lädt alle versionierten SQL-Migrationen beim
  Start und schließt die Datenbank wieder, falls eine Migration fehlschlägt.
- `docker-compose.local.yaml` startet `runtime` und `novooa-ml`. Nur
  `runtime` bindet `127.0.0.1:${LOCAL_RUNTIME_PORT:-8090}`; `novooa-ml` hat
  keinen Host-Port und hängt ausschließlich in `novooa-private`.
- Beim Start legt die Runtime idempotent `local-user` und `local-team` an.
  `POST /v1/task-runs` legt einen Run für diesen lokalen Arbeitsbereich an;
  `POST /v1/task-runs/review` setzt Freigaben und Eingaben fort.
- Der native Client verwaltet Aufgaben über `GET`, `PUT` und `DELETE
  /v1/tasks`, Runs und Aktivitäten über `GET /v1/task-runs` und
  `GET /v1/activities`, Wissensnotizen über `/v1/knowledge-notes`, Zeitpläne
  über `/v1/task-triggers` sowie Dateien und Ordner über `/v1/files` und
  `/v1/folders`. Dateien werden als Base64-kodierte JSON-Payloads bis zur
  lokalen Runtime übertragen und dort im Volume abgelegt. Diese Endpunkte sind
  ausschließlich Loopback-APIs der lokalen Runtime und kein Cloud-HTTP-Vertrag.
- `006_task_run_jobs.sql` ergänzt eine haltbare SQLite-Jobqueue. Der
  `PollingTaskRunWorker` least Jobs, bestätigt erfolgreiche Ausführungen und
  versucht fehlgeschlagene Jobs mit 30 bis 300 Sekunden Backoff höchstens
  dreimal erneut.
- Der `PollingTaskTriggerWorker` wertet fällige Zeitpläne alle 30 Sekunden
  aus, erzeugt Runs über den gemeinsamen Scheduling-Use-Case und schreibt den
  nächsten Ausführungszeitpunkt atomar in SQLite fort.
- `HttpPythonModelInputTransformer` und `SidecarOnnxInferenceRuntime` leiten
  Bildvorverarbeitung und ONNX-Inferenz an `novooa-ml` weiter. Ohne Sidecar
  meldet die Runtime eine klare lokale ML-Fehlermeldung statt Cloud-Fallback.

## Lokaler Start

```bash
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos --dart-define=NOVOOA_RUNTIME=local
```

Der Stack legt das benannte Volume `novooa-local_novooa-data` an. Ein
`docker compose down` entfernt weder dieses Volume noch SQLite, Dateien oder
Modellartefakte.

## Nächste Schritte

1. Docker-Engine- und Stack-Status in der Desktop-App anzeigen sowie den Stack
   kontrolliert starten und stoppen.
2. Geräteauthentifizierung für lokale HTTP-Endpunkte und Relay-Events ergänzen;
   ausgehende Nachrichten bleiben bis dahin bewusst deaktiviert.
3. Secret-Mount, Workspace-Geräteidentität, SQLite-Backups und versionierte
   Images für die auslieferbare Desktop-App umsetzen.
