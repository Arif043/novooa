# Lokale Runtime

Dieser Ordner enthält die lokale Persistenz-Struktur für eine spätere
vollständig lokal ausführbare novooa-Version.

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
- `LocalOnnxInferenceRuntime`
- `LocalPythonOnnxWorker`
- `LocalPythonModelInputTransformer`

Der konkrete SQLite-Treiber ist bewusst noch nicht festgelegt. Die Adapter
nutzen vorerst `LocalSqlDatabase`, damit wir den Treiber später austauschen
können, ohne die Runtime-Ports erneut anzufassen.

Migrationen werden über `SqlMigrationRunner` angewendet. Der Runner erwartet
bereits aufbereitete Statements; ein lokaler CLI kann die Dateien aus
`migrations/` lesen und mit `migrationFromSqlFile` in Migrationen umwandeln.

## Python-ONNX-Runtime

Die lokale ONNX-Ausführung und Bildvorverarbeitung nutzen getrennte Python-
Worker unter `python/onnx_worker.py` und `python/input_transform_worker.py`.
Die Runtime wird bewusst in einer lokalen virtuellen Umgebung installiert:

```bash
python3 -m venv .novooa/python
.novooa/python/bin/python -m pip install -r local-runtime/python/requirements.txt
```

Der spätere lokale Composition Root übergibt diesem Worker den Interpreterpfad.
Cloud Functions benötigen und enthalten diese Python-Abhängigkeiten nicht.
