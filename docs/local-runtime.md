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
```

Die Migration
[`004_model_catalog.sql`](../local-runtime/migrations/004_model_catalog.sql)
ergänzt den ONNX-Modellkatalog in der Tabelle `model_catalog`.

Dateien liegen im lokalen Dateisystem:

```text
.novooa/
  files/{teamId}/{fileId}/versions/{versionId}/{fileName}
  model-artifacts/{artifactId}/versions/{versionId}/model.onnx
  knowledge/{teamId}/...
```

ONNX-Inferenz läuft lokal in einem dedizierten Python-Prozess. Dieser erhält
keine Speicherpfade, sondern verifizierte Modellbytes und Tensoren über das
standardisierte Worker-Protokoll. Die Abhängigkeiten liegen in
[`local-runtime/python/requirements.txt`](../local-runtime/python/requirements.txt);
der spätere lokale Composition Root konfiguriert den Python-Interpreter und
den Workerpfad explizit.

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
- Lokale SQL-Adapter für Tasks, Runs, Aktivitäten, Trigger und Wissensbasis
  hängen nur an `LocalSqlDatabase`.
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

## Nächste Schritte

1. Konkreten SQLite-Treiber für `LocalSqlDatabase` anbinden.
2. Lokalen Worker-Prozess mit `TaskRunWorkerStores` starten.
3. Lokalen HTTP-Endpunkt für Relay-Events implementieren.
4. Cloud Relay für Twilio Webhooks und ausgehende Nachrichten trennen.
