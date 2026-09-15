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

Die Flutter-Desktop-App verwendet für Fach- und Nutzdaten ausschließlich den
lokalen Runtime-Endpunkt. Sie benötigt weder ein Firebase-Konto noch eine
Internetverbindung im laufenden Betrieb. Für die einmalige Aktivierung benötigt
die Runtime eine HTTPS-Verbindung zum novooa-Lizenz-Gateway.
Benachrichtigungen und externe Trigger werden später über einen novooa-Relay
vermittelt, nicht über den Client. Die App verwaltet weder SQLite-Dateien noch
Docker-Volumes direkt. Das automatische
Prüfen, Starten und Überwachen des versionierten Compose-Stacks gehört zur
auslieferbaren Desktop-App und ist noch nicht implementiert.

```text
Flutter-Desktop-App
  -> Docker Desktop / Docker Engine
      -> novooa-runtime (Node)
          lokale API, Scheduler, Task-Worker, SQLite-Adapter, Relay-Client
      -> novooa-ml (Python)
          Tensor-Transformationen und ONNX-Inferenz
```

`novooa-runtime` ist der einzige Dienst mit einem veröffentlichten Host-Port.
Compose veröffentlicht standardmäßig `8090` auf allen Host-Schnittstellen, damit
native novooa-Clients im selben LAN ihn erreichen können. Der Host-Client nutzt
dabei weiterhin automatisch `127.0.0.1`; weitere Clients geben ausschließlich
die private IPv4-Adresse des Runtime-Hosts ein. `novooa-ml` ist
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

Der private Signaturschlüssel bleibt außerhalb des Daten-Volumes. Die Runtime
speichert unter `credentials/license-state.json` die signierte Lizenz und ein
verschlüsseltes Aktivierungsgeheimnis mit restriktiven Dateirechten. Das Geheimnis
ist mit dem bei der Installation erzeugten Runtime-Master-Key geschützt. Die Datei
enthält weder den Kunden-Token, einen privaten Signaturschlüssel noch
Firebase-Credentials. Die Runtime darf ausgehend den novooa-Relay und konfigurierte
Modellprovider erreichen; der ML-Dienst erhält keinen direkten Internetzugang.

## Lokale Datenhaltung

SQLite ist der Default für strukturierte lokale Daten. Es braucht keinen Server,
ist transaktional und eignet sich für Aufgaben, Runs, Aktivitäten, Trigger,
Teams, Kanäle, Wissensbasis-Metadaten und Modellkataloge.

Anwendungsprotokolle liegen getrennt von Workflow-Aktivitäten in
`application_logs`. Der lokale `ApplicationLogger` speichert strukturierte
Info- und Fehlerereignisse dort und gibt sie zusätzlich als JSON nach Docker-
Stdout aus. Der native Flutter-Client sendet seine eigenen Ereignisse per
`POST /v1/application-logs` an die Runtime; diese vergibt ID und
Zeitstempel und markiert die Quelle als `client`. `GET /v1/application-logs`
liefert die jüngsten Einträge an den Client; dieser zeigt sie im Tab
**Aktivitäten → Protokoll**. Der gleiche Port wird in der Cloud durch den
`FirebaseApplicationLogger` auf Firebase/Cloud Logging abgebildet.

Die erste Migration liegt in
[`local-runtime/migrations/001_initial.sql`](../local-runtime/migrations/001_initial.sql).
Sie legt diese Tabellen an:

```text
teams
team_members
tasks
task_runs
activities
application_logs
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
nicht im Klartext in SQLite. Die Migration
[`011_language_model_secrets.sql`](../local-runtime/migrations/011_language_model_secrets.sql)
speichert sie AES-256-GCM-verschlüsselt; `secret_ref` verweist auf den
jeweiligen Eintrag. Der Master-Key liegt separat außerhalb des Daten-Volumes.
Die Flutter-Einstellungen bieten **Google AI**, **Ollama (lokal)** und
OpenAI-kompatible Anbieter an und verbinden sie über `POST
/v1/language-model-connections`. Die Runtime lädt dessen Modellkatalog und
speichert alle verfügbaren Textmodelle unter einer gemeinsamen Verbindung. Die
Modellauswahl findet anschließend im TaskBuilder statt; dort liest der Client
den Katalog über `GET /v1/language-models`. API-Keys werden in keiner Antwort
ausgegeben. Ollama verwendet ohne weitere Eingabe
`http://host.docker.internal:11434/v1` und Genkits OpenAI-kompatiblen Adapter.
Für einen abweichenden OpenAI-kompatiblen Dienst wird als Base-URL
`http://host.docker.internal:<port>/v1` verwendet. Externe Anbieter benötigen
eine HTTPS-URL und einen API-Key. Für Ollama verwendet die Runtime intern einen
nicht geheimen Platzhalter.

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

Workflow-Werte werden vor der lokalen Inferenz gemäß Manifest in Tensoren
transformiert. `input_transform_worker.py` verwendet für Bildquellen eine
erweiterbare Registry für Dekodierung, Skalierung, Layout und Normalisierung.
Weitere Quelltypen erhalten eigene Strategien; weder die Pipeline noch der
Modell-Baustein sind an Firebase Storage oder Bilder gekoppelt.

## Lizenz und lokale Identität

Die Runtime ist ohne gültigen Lizenzschlüssel nicht nutzbar. Beim Kauf stellt
novooa einen zwölfstelligen Token aus dem Alphabet `A-H`, `J-N`, `P-Z` und
`2-9` aus. Der Kunde gibt ihn auf der nativen Aktivierungsseite ein. Der Client
sendet ihn ausschließlich an `POST /v1/license/activate`; die Runtime löst ihn
per HTTPS am novooa-Lizenz-Gateway ein.

Firestore speichert den SHA-256-Hash des Tokens als Dokument-ID, niemals den
Roh-Token. Das Dokument enthält mindestens `licenseId`, `name`,
`workspaceId`, `expiresAt` und `inUse`. Die Aktivierung läuft atomar ab: Ist
`inUse` false und die Lizenz nicht abgelaufen, erzeugt das Gateway eine neue
`activationId` und ein zufälliges Aktivierungsgeheimnis. Es speichert nur dessen
Hash, setzt `inUse` auf true und liefert der Runtime eine Ed25519-signierte Lizenz
plus Aktivierungsgeheimnis.

Die Runtime prüft die Signatur mit ihrem öffentlichen Verifikationsschlüssel und
speichert Lizenz und Geheimnis verschlüsselt mit ihrem lokalen Master-Key. Damit
kann eine Lizenz immer nur durch diese konkrete Aktivierung verwendet werden, ohne
einen Gerätefingerabdruck zu benötigen. Fachliche Runtime-Endpunkte liefern ohne
gültige Lizenz `423`; Task- und Trigger-Worker starten dann keine Jobs. Bis zum
signierten Ablaufdatum ist keine ständige Internetverbindung nötig.

In den Runtime-Einstellungen kann der Kunde die Lizenz entfernen. Dies ruft
`POST /v1/license/release` auf. Die Runtime übergibt die signierte
`activationId` sowie ihr Aktivierungsgeheimnis; das Gateway vergleicht dessen
Hash, setzt `inUse` atomar auf false und löscht die lokale Aktivierung. Danach
kann derselbe Token eine andere Runtime aktivieren. Eine alte signierte Lizenz
wird vom Push-Relay über ihre nicht mehr aktive `activationId` abgelehnt.

Der Produktiv-Container benötigt diese Variablen:

```text
LOCAL_RUNTIME_LICENSE_GATEWAY_URL=https://<region>-<projekt>.cloudfunctions.net/issueLocalRuntimeLicense
LOCAL_RUNTIME_LICENSE_PUBLIC_KEY_FILE=/run/secrets/novooa_runtime_license_public_key
LOCAL_RUNTIME_PUSH_RELAY_URL=https://<region>-<projekt>.cloudfunctions.net/localRuntimePushRelay
```

Der Verifikationsschlüssel ist kein Kundengeheimnis und dient ausschließlich dazu,
die Server-Signatur offline zu prüfen. Im Compose-Betrieb wird er bevorzugt über
`LOCAL_RUNTIME_LICENSE_PUBLIC_KEY_FILE` aus dem Docker-Secret
`novooa_runtime_license_public_key` gelesen. Der zugehörige private
Ed25519-Schlüssel ist als Firebase-Secret `LOCAL_RUNTIME_LICENSE_SIGNING_KEY`
ausschließlich im Lizenz-Gateway verfügbar. Er gehört weder in ein Image,
Compose-File noch in die Desktop-App.

Das Checkout-Compose setzt absichtlich `NOVOOA_LOCAL_DEVELOPMENT=true`; diese
Entwicklungsausnahme erzeugt nur den lokalen Beispielarbeitsbereich und darf nicht
als Produktivmodus ausgeliefert werden.

Der Vertriebsprozess benötigt einmalig Application Default Credentials und das
Zielprojekt:
`gcloud auth application-default login` und
`gcloud config set project syscat-90bff`. Anschließend erstellt er einen eindeutigen
Token und den gehashten Firestore-Eintrag mit
`npm --prefix functions run licenses:issue-local -- --name "Kunde GmbH" --expires-at 2027-09-16T00:00:00Z`.
Optional sind `--license-id` und `--workspace-id`; `--expires-at` ist verpflichtend.
Die Ausgabe ist der einmalig an den Kunden zu übergebende zwölfstellige Token. Der
Prozess benötigt Firebase-Admin-Zugang, aber keinen Signaturschlüssel.

Der lokale SQLite-Arbeitsbereich wird deterministisch aus der signierten
Arbeitsbereich-ID erzeugt. Die lokale Desktop-App verwendet für UI-seitige
Metadaten einen nicht sicherheitsrelevanten lokalen Benutzer; die Runtime bleibt
für die tatsächliche Arbeitsbereichsgrenze maßgeblich.

## Push-Benachrichtigungen

Die Desktop-App registriert ihren FCM-Token über `POST /v1/push-devices` bei
der lokalen Runtime. Diese leitet die Registrierung zusammen mit der
signierten, aktiven Lizenz an `localRuntimePushRelay` weiter. Der Cloud-Relay
prüft Lizenzsignatur, Status und Arbeitsbereich erneut und speichert Tokens
unter der Lizenz-ID. Wartet eine lokale Aufgabe auf eine Freigabe, sendet die
Runtime den Push über denselben Relay. Fehler beim Relay werden protokolliert,
blockieren die lokale Aufgabe aber nicht.

Der Relay verarbeitet transportneutrale Push-Nachrichten mit `title`, `body`
und einem String-zu-String-Datenfeld. `registerDevice` und `removeDevice`
verwalten die Geräte einer Lizenz; `send` stellt jede fachliche
Push-Benachrichtigung an deren registrierte Geräte zu. Freigaben sind damit
ein Anwendungsfall des allgemeinen Push-Vertrags, nicht Teil der Relay-API.

Push ist in der Standalone-Variante optional und standardmäßig deaktiviert.
Dadurch lässt sich der macOS-Client ohne Apple-Entwicklungszertifikat bauen. Die
normalen Runtime-, Datei- und Netzwerkfunktionen sind davon nicht betroffen. Der
Push-Schalter erscheint nur, wenn Firebase dafür initialisiert wurde.

Für eine signierte macOS-Auslieferung kann Push mit
`--dart-define=NOVOOA_PUSH_ENABLED=true` aktiviert werden. Dann müssen zusätzlich
APNs-Credentials und die `aps-environment`-Berechtigung im signierten
App-Bundle eingerichtet werden.

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
  manifestbasierte Quellen als Tensoren auf. Bild- und unveränderte
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
  `runtime` veröffentlicht fest `8090` auf allen Host-Schnittstellen; `novooa-ml` hat
  keinen Host-Port und hängt ausschließlich in `novooa-private`.
- Beim Start stellt die Runtime ohne Lizenz nur `/healthz`, `GET /v1/license`
  und `POST /v1/license/activate` und `POST /v1/license/release` bereit. Nach erfolgreicher Aktivierung legt
  sie den durch die signierte Lizenz bestimmten Teamarbeitsbereich idempotent
  an. Erst dann sind Ausführung, Review, Dateien, Wissensbasis und Zeitpläne
  erreichbar.
- Der native Client verwaltet Aufgaben über `GET`, `PUT` und `DELETE
  /v1/tasks`, Runs und Aktivitäten über `GET /v1/task-runs` und
  `GET /v1/activities`, Wissensnotizen über `/v1/knowledge-notes`, Zeitpläne
  über `/v1/task-triggers` sowie Dateien und Ordner über `/v1/files` und
  `/v1/folders`. Dateien werden als Base64-kodierte JSON-Payloads bis zur
  lokalen Runtime übertragen und dort im Volume abgelegt. Diese Endpunkte sind
  Runtime-APIs im lokalen Netzwerk und kein Cloud-HTTP-Vertrag.
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
npm --prefix functions run local-runtime:prepare -- \
  --secret-file ../.novooa/runtime-master-key
docker compose -f docker-compose.local.yaml up --build --detach
curl http://127.0.0.1:8090/healthz
docker compose -f docker-compose.local.yaml ps
flutter run -d macos --dart-define=NOVOOA_RUNTIME=standalone
```

Der Stack legt das benannte Volume `novooa-local_novooa-data` an. Ein
`docker compose down` entfernt weder dieses Volume noch SQLite, Dateien oder
Modellartefakte. Beim ersten Befehl entsteht ein zufälliger 32-Byte-Master-Key
in `.novooa/runtime-master-key`; das Verzeichnis ist ignoriert. Compose bindet
ihn nur für den Node-Dienst als `/run/secrets/novooa_runtime_master_key` ein.
Eine auslieferbare Desktop-App erzeugt dieselbe Datei bei der Installation im
betriebssystemspezifischen Novooa-Datenverzeichnis und setzt
`NOVOOA_LOCAL_SECRETS_DIRECTORY` darauf. Der Master-Key darf weder im Docker-
Image noch im SQLite-Volume liegen. Bei dessen Verlust müssen gespeicherte
Provider-Keys erneut hinterlegt werden.

## Nächste Schritte

1. Docker-Engine- und Stack-Status in der Desktop-App anzeigen sowie den Stack
   kontrolliert starten und stoppen.
2. Das Lizenz-Gateway mit Firebase-Secret und Produktions-Compose ausrollen.
3. Freigabe-Ereignisse über den Cloud-Gateway in Firestore/FCM spiegeln.
4. SQLite-Backups und versionierte Images für die auslieferbare Desktop-App
   umsetzen.
