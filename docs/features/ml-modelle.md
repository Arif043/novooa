# ML-Modelle

## Zweck

Das Feature verwaltet einen plattformunabhängigen Katalog klassischer
Machine-Learning-Modelle. In der ersten Ausbaustufe unterstützt novooa ONNX.
Ein Katalogeintrag beschreibt das Modell, seinen logischen Artefaktverweis und
das vollständige Manifest für Ein- und Ausgaben; es enthält weder Firebase-Pfade noch
Provider-spezifische Download-URLs.

## Verantwortlichkeiten

- System- und künftig teamweite Modelle über `ModelCatalog` auffindbar machen.
- ONNX-Artefakte über `artifactId` und `versionId` logisch referenzieren und
  vor der Inferenz auf Größe sowie SHA-256 prüfen.
- Erwartete Tensoren, Vorverarbeitung und Ergebnissemantik verbindlich
  dokumentieren und validieren.
- Das Manifest in Firestore und SQLite identisch persistieren.

## Katalogeintrag

`scope` trennt Modellverfügbarkeit von der technischen Ablage:

- `system`: novooa stellt das Modell allen Teams bereit.
- `team`: später ein teamweit bereitgestelltes Modell. Hochladen durch Nutzer
  ist in der ersten Ausbaustufe noch nicht vorgesehen.

`artifactReference` ist eine logische Referenz. `ModelArtifactReader` löst sie
in verifizierte Modellbytes auf. Sein Firebase-Adapter liest Cloud Storage, der
lokale Adapter das lokale Dateisystem. Beide prüfen Größe und SHA-256 vor der
Rückgabe; die ONNX-Runtime kennt deshalb keinen Speichertyp.

```ts
{
  id: "mobilenet-v3",
  title: "MobileNet V3",
  description: "Klassifiziert ein Bild.",
  tags: ["bild", "klassifikation"],
  scope: {type: "system"},
  runtime: "onnx",
  artifactReference: {
    artifactId: "mobilenet-v3-artifact",
    versionId: "2026-08",
    format: "onnx",
    contentType: "application/onnx",
    sizeBytes: 10500000,
    sha256: "<sha-256>",
  },
  contract: {inputs: [...], outputs: [...]},
}
```

## Manifest

Alle Modelle arbeiten an der Runtime-Grenze mit Tensoren. Ein Eingang beschreibt
zusätzlich seine Quelle (`image`, `file`, `text`, `datetime`, `number`,
`boolean`, `json` oder `tensor`) und eine Vorverarbeitung. Ein Ausgang beschreibt
seine fachliche Semantik sowie optionale Nachverarbeitung.

```ts
{
  inputs: [{
    name: "image",
    source: "image",
    dataType: "float32",
    shape: ["dynamic", 3, 224, 224],
    preprocessing: [
      {type: "image.decode", parameters: {colorSpace: "rgb"}},
      {type: "image.resize", parameters: {width: 224, height: 224}},
      {type: "tensor.layout", parameters: {order: "channelsFirst"}},
      {type: "tensor.normalize", parameters: {
        mean: [0.485, 0.456, 0.406], std: [0.229, 0.224, 0.225],
      }},
    ],
  }],
  outputs: [{
    name: "scores",
    dataType: "float32",
    shape: ["dynamic", 1000],
    semantic: "classification.scores",
    postprocessing: [],
  }],
}
```

Transformationen verwenden einen offenen Typnamen plus Parameter. Dieselbe
`TransformationPipeline` wird vor der ONNX-Inferenz als `preprocessing` und
danach als `postprocessing` verwendet. Der Transformationskatalog enthält
damit Bild-, Tensor-, Geometrie-, Sequenz- und JSON-Transformationen; eine
separate Operationsabstraktion gibt es nicht. Die Transformations-Registry
ordnet jedem Typ eine Strategie zu. Neue Strategien erfordern daher keine
Änderung am Manifest.

## Persistenz

Cloud: `modelCatalog/{modelId}` in Firestore. Lokal: SQLite-Tabelle
`model_catalog` aus Migration `004_model_catalog.sql`. Beide Adapter
implementieren den Domain-Port `ModelCatalog`.

Artefakte liegen ausschließlich in der Infrastructure unter dem technischen
Pfad `model-artifacts/{artifactId}/versions/{versionId}/model.onnx`. Dieser
Pfad ist kein Bestandteil eines Katalogeintrags oder Workflow-Werts.

## Inferenz

`RunModelInference` führt ein bereits aufgelöstes Modell aus: Es prüft die
vorbereiteten Eingabe-Tensoren gegen das Manifest, liest das Artefakt genau
einmal und validiert auch die Tensoren der Runtime-Ausgabe gegen die
Ausgangsdefinition im Manifest. `RunModelInferenceWithSources` löst davor die Verfügbarkeit
für ein Team auf, ordnet alle Workflow-Quellen dem Manifest zu, bereitet sie vor
und delegiert anschließend an `RunModelInference`.

```text
ModelCatalog → RunModelInferenceWithSources
                     ↓
             PrepareModelInputs
                     ↓
             RunModelInference
                     ↓
   ModelArtifactReader + ModelInferenceRuntime
```

Die Runtime erhält ausschließlich verifizierte Modellbytes und typisierte
Tensoren. Sie kennt weder Firestore noch Firebase Storage, Dateipfade oder
Workflow-Werte.

### Lokale ONNX-Runtime

`LocalOnnxInferenceRuntime` delegiert an `LocalPythonOnnxWorker`. Der Worker
startet `local-runtime/python/onnx_worker.py` mit einem konfigurierten lokalen
Python-Interpreter. Modell und Tensoren werden als Base64 über `stdin`
übertragen; der Worker erstellt daraus eine ONNX-Runtime-Session mit dem CPU
Execution Provider und liefert Tensoren über `stdout` zurück.

```bash
python3 -m venv .novooa/python
.novooa/python/bin/python -m pip install -r local-runtime/python/requirements.txt
```

Der lokale Composition Root injiziert den Interpreterpfad sowie den Pfad zum
Worker. Dadurch ist die Python-Abhängigkeit weder Teil der Cloud Functions noch
eine implizite globale Voraussetzung.

## Transformationen

`PrepareModelInputs` ordnet fachliche Quellen den Eingangsdefinitionen des
Manifests zu. Eine Quelle kann Text, Datum/Uhrzeit, Zahl, Boolean, JSON,
Datei- oder Bildbytes oder ein bereits vorbereiteter Tensor sein.
`ModelInputTransformer` ist der Port für die technische Umwandlung. Erst danach
nimmt `RunModelInference` ausschließlich Tensoren entgegen.

```text
Workflow-Wert → Adapter → Modellquelle → PrepareModelInputs
                                          ↓
                                   ModelInputTransformer
                                          ↓
                                      ModelTensor
```

Der `modelInference`-Baustein adaptiert alle Vorgängerwerte in der Reihenfolge
der eingehenden Kanten auf Modellquellen. Erst das Manifest prüft Anzahl
und Typ dieser Quellen. Datei- und Bildwerte lädt der Adapter über den
bestehenden `TeamFileContentReader`; eine Firebase-Storage-Referenz wird nicht
in das Manifest oder an die Runtime weitergereicht. Seine primäre Ausgabe
ist JSON mit Modell-ID und Tensoren (`name`, `semantic`, `dataType`, `shape`,
`dataBase64`); beispielsweise ist der erste Tensor über
`{{modell1.value.outputs.0.dataBase64}}` referenzierbar.

Lokal erfüllt `LocalPythonModelInputTransformer` den Port. Sein Worker baut
eine `TransformationRegistry` aus eigenständigen Strategien zusammen. Dieselbe
Registry ist die Erweiterungsstelle für Ein- und Ausgangstransformationen.
Neue Transformationen erfordern damit nur eine zusätzliche Strategieklasse und
deren Registrierung im lokalen Composition Root, nicht aber eine Änderung der
Pipeline oder des Manifests.

Aktuell enthält die lokale Runtime konkrete Strategien für Bildquellen und
unveränderte Tensoren. Verträge mit Text-, Zahlen-, Boolean-, JSON- oder
Dateiquellen werden bereits korrekt gebunden und validiert; ihre technische
Umwandlung wird erst durch die jeweils passende zusätzliche Strategie aktiviert.

| Transformation | Parameter | Wirkung |
| --- | --- | --- |
| `image.decode` | `colorSpace`: `rgb`, `rgba`, `grayscale` | Dekodiert und setzt den Farbraum. |
| `image.resize` | `width`, `height`, optional `colorSpace` | Skaliert mit LANCZOS. |
| `tensor.layout` | `order`: `channelsFirst`, `channelsLast` | Ordnet HWC und CHW um. |
| `tensor.normalize` | `mean`, `std` | Normalisiert jeden Farbkanal. |

Der Worker fügt bei einem Manifest mit einer Eingabeform wie `["dynamic", 3, 224, 224]` den Batch-
Index hinzu, wenn das Bild zunächst als `[3, 224, 224]` vorliegt. Vor der
Rückgabe prüft er Form, Datentyp und Byte-Länge. Tensorquellen werden zunächst
nur ohne Vorverarbeitung durchgereicht; weitere Tensorstrategien ergänzen wir
über denselben Port.

### Cloud-Runtime

Die Cloud-Inferenz läuft in einem privaten Cloud-Run-Container. Der Container
verwendet denselben Domain-Use-Case `RunModelInferenceWithSources` wie die
lokale Variante, jedoch mit Firestore als `ModelCatalog` und Cloud Storage als
`ModelArtifactReader`. ONNX Runtime und die Transformationsstrategien laufen
im Container in Python. Dadurch bleiben Katalog, Manifest und Ausführungspfad
identisch; nur die technische Composition unterscheidet sich.

Der HTTP-Adapter nimmt ausschließlich transportierbare Werte entgegen:

```text
POST /v1/inferences
{ teamId, modelId, inputs: [{type, ...}] }
```

Bild- und Dateiquellen enthalten Base64-Bytes, Tensoren enthalten `name`,
`dataType`, `shape` und `dataBase64`. Der Service gibt die gemäß Manifest
validierten Ausgabe-Tensoren im selben portablen Format zurück. Weder die
Anfrage noch das Manifest enthalten Firebase-Pfade.

Das Gateway-Image entsteht mit:

```bash
docker build -f functions/Dockerfile.model-inference -t novooa-model-inference .
docker run --rm -p 8080:8080 novooa-model-inference
```

Das produktive Linux-Image erstellt Cloud Build aus dem Repository-Root und
legt es in Artifact Registry ab:

```bash
gcloud builds submit --project=syscat-90bff --region=europe-west3 \
  --config=cloudbuild.model-inference.yaml \
  --substitutions=_IMAGE=europe-west3-docker.pkg.dev/syscat-90bff/novooa/model-inference:<version>
```

Der Container hört auf `0.0.0.0:$PORT`; der Dienst bleibt privat. Die
`runTaskRunTask`-Function verwendet `CloudRunModelInference` und ruft ihn mit
einem Google-ID-Token auf. Die Service-URL ist der Functions-Parameter
`MODEL_INFERENCE_SERVICE_URL`; die Function-Runtime benötigt die IAM-Rolle
`roles/run.invoker` auf genau diesem Cloud-Run-Service.
Vor dem Deploy der Function muss der Parameter in
`functions/.env.<projectId>` auf die HTTPS-Service-URL gesetzt sein.

Der Container hat einen eigenen Runtime-Service-Account. Er erhält nur
`roles/datastore.user` sowie Lesezugriff auf den Artefakt-Bucket; die
Task-Worker-Function ist der einzige heutige Aufrufer, weil nur sie
`modelInference`-Bausteine innerhalb eines Task-Runs ausführt. Künftige
Backend-Executoren benötigen dieselbe gezielte `roles/run.invoker`-Bindung.

Der lokale Composition Root verdrahtet denselben Use Case mit einem
Dateisystemkatalog, lokalen Modellartefakten, dem Python-Transformer und der
ONNX-Runtime.

### Lokaler Docker-Stack

Für die lokale Entwicklung läuft der Inferenzdienst in derselben Struktur wie
in Cloud Run: ein Node-Gateway und ein Python-Sidecar. Docker Compose ersetzt
nur den Cloud-Run-Orchestrator. Im lokalen Modus verwendet das Gateway
ausschließlich den eingebundenen Runtime-Ordner, keinen Firebase-Adapter und
keine Google-Anmeldedaten.

```bash
docker compose -f docker-compose.model-inference.yaml up --build
```

Der Dienst ist ausschließlich als `http://127.0.0.1:8080` erreichbar. Für den
Functions-Emulator setzt `functions/.env.local`:

```text
MODEL_INFERENCE_SERVICE_URL=http://127.0.0.1:8080
```

Im Emulator wählt `modelInference()` hierfür den lokalen HTTP-Adapter ohne
Google-ID-Token. Außerhalb des Emulators bleiben ausschließlich HTTPS und die
Cloud-Run-ID-Token-Authentifizierung zulässig.

Modelle werden vor dem Start lokal installiert. Der Installer prüft ONNX-Datei
und Manifest und schreibt Artefakt sowie Katalogeintrag in `.novooa`:

```bash
npm --prefix functions run models:install-local -- \
  --runtime-root .novooa \
  --manifest models/mobilenet-v3/model.json \
  --artifact models/mobilenet-v3/model.onnx
```

Der Runtime-Ordner hat die Struktur:

```text
.novooa/
  model-catalog/<base64url-modell-id>.json
  model-artifacts/<artifact-id>/versions/<version-id>/model.onnx
```

Docker Compose bindet diesen Ordner nur lesend ein. Der Installer wird daher
auf dem Host ausgeführt; der Gateway kann installierte Modellversionen niemals
verändern.

Der Python-Sidecar liegt ausschließlich im internen `novooa-private`-Netzwerk und
besitzt keinen ausgehenden Netzwerkzugang. Das Gateway ist zusätzlich am
`novooa-public`-Netzwerk, damit seine auf `127.0.0.1` beschränkte Portfreigabe
auf Docker Desktop zuverlässig erreichbar ist. Der heutige
Firebase-Functions-Emulator kann den Stack für Entwicklungstests aufrufen,
ist aber selbst noch kein vollständig lokaler Aufgaben-Runner: Aufgaben,
Dateien und Runs stammen dort weiterhin aus Firebase. Die vollständig lokale
Ausführung benötigt als nächsten Schritt den geplanten SQLite-Task-Runner.

#### Session-Cache

Eine Cloud-Run-Instanz besteht aus einem Node-Gateway und einem Python-
Sidecar. Das Gateway prüft Manifest und Modellverfügbarkeit, löst Artefakte aus
Cloud Storage auf und hält die zuletzt verwendeten Artefakte im lokalen LRU-
Cache. Der Sidecar hält ONNX-Sessions mit dem Schlüssel
`artifactId:versionId:sha256` in einem getrennten LRU-Cache. Dadurch wird eine
Modellversion nur beim ersten Zugriff einer warmen Instanz aus Storage geladen
und als ONNX-Session initialisiert.

Die bestehende Bildvorverarbeitung verwendet in dieser ersten Stufe weiter den
lokalen Python-Worker. Sie wird in einem folgenden Schritt auf den Sidecar
umgestellt, damit auch ihre Prozesse zwischen Anfragen wiederverwendet werden.

Der Sidecar meldet einen verworfenen Session-Cache-Eintrag explizit zurück.
Das Gateway lädt dann dieselbe unveränderliche Artefaktversion erneut und
wiederholt nur diese Inferenz. Cache-Inhalte sind flüchtig; Cloud Storage bleibt
die geprüfte Quelle der Wahrheit.

Die Vorlage `functions/cloudrun/model-inference-service.yaml.template`
konfiguriert zunächst eine Concurrency von `1`, höchstens zehn Instanzen und
eine warme Instanz. Vor dem Deployment müssen `NODE_IMAGE` und `SIDECAR_IMAGE`
durch die beiden Artifact-Registry-Images ersetzt werden. Die Cache-Größen
werden über `MODEL_ARTIFACT_CACHE_ENTRIES` und
`MODEL_SESSION_CACHE_ENTRIES` gesteuert.

## Betreiber-Publishing

In der ersten Ausbaustufe veröffentlicht ausschließlich novooa
Systemmodelle. Dazu gibt es keine öffentliche Function und keine
App-Oberfläche. Der Betreiber startet eine nicht-interaktive TypeScript-CLI,
die ausschließlich Firestore und Cloud Storage des angegebenen GCP-Projekts
verwendet.

```bash
gcloud auth application-default login
npm --prefix functions run models:publish -- \
  --project syscat-90bff \
  --manifest models/mobilenet-v3/model.json \
  --artifact models/mobilenet-v3/model.onnx \
  --dry-run
```

Ohne `--dry-run` lädt die CLI das Artefakt hoch und registriert den
Katalogeintrag. Optional überschreibt `--bucket <bucket>` den aus der
Projekt-ID abgeleiteten Firebase-Bucket. `--python <pfad>` wählt den
Interpreter für die ONNX-Prüfung; ohne Angabe wird `PYTHON_EXECUTABLE` oder
`python3` verwendet. Die Betreiberidentität benötigt Schreibzugriff auf
`modelCatalog` sowie `storage.objects.create` auf dem Artefakt-Bucket.

Jedes Modell besteht mindestens aus einer ONNX-Datei und einem versionierten
Manifest:

```text
models/mobilenet-v3/
├── model.onnx
└── model.json
```

```json
{
  "id": "mobilenet-v3",
  "title": "MobileNet V3",
  "description": "Klassifiziert Bilder.",
  "tags": ["bild", "klassifikation"],
  "artifact": {
    "artifactId": "mobilenet-v3",
    "versionId": "2026-08"
  },
  "contract": {
    "inputs": [{
      "name": "input",
      "source": "image",
      "dataType": "float32",
      "shape": ["dynamic", 3, 224, 224],
      "preprocessing": [
        {"type": "image.decode", "parameters": {"colorSpace": "rgb"}},
        {"type": "image.resize", "parameters": {"width": 224, "height": 224}},
        {"type": "tensor.layout", "parameters": {"order": "channelsFirst"}},
        {"type": "tensor.normalize", "parameters": {
          "mean": [0.485, 0.456, 0.406],
          "std": [0.229, 0.224, 0.225]
        }}
      ]
    }],
    "outputs": [{
      "name": "scores",
      "semantic": "classification.scores",
      "dataType": "float32",
      "shape": ["dynamic", 1000],
      "postprocessing": []
    }]
  }
}
```

Die CLI validiert Manifest und Modell, prüft das Modell durch das Öffnen einer
ONNX-Runtime-Session und vergleicht Namen, Datentypen sowie statische
Tensorformen mit dem Manifest. Gegenwärtig akzeptiert sie Bild- und
Tensoreingänge, die registrierten Bildtransformationen sowie keine
Ausgangsnachverarbeitung. Anschließend berechnet sie Größe und SHA-256,
schreibt das Artefakt unveränderlich nach
`model-artifacts/<artifactId>/versions/<versionId>/model.onnx` und speichert
erst danach den Firestore-Katalogeintrag. `ifGenerationMatch: 0` verhindert,
dass eine bestehende Modellversion überschrieben wird.

Ein fehlgeschlagener Katalogeintrag kann ein bereits hochgeladenes, aber nicht
referenziertes Artefakt hinterlassen. Solche Artefakte werden später von einem
separaten Betreiber-Cleanup entfernt; eine Dateiablage und Firestore bieten
keine gemeinsame Transaktion.

## Nächste Schritte

1. Einen Betreiber-Cleanup für nicht referenzierte Modellartefakte ergänzen.
2. Weitere Eingabe- und Ausgangstransformationen als Strategien ergänzen.

## Verwandt

- [Aufgabe-Ausführung](./aufgabe-ausfuehrung.md)
- [Dateien](./dateien.md)
- [Lokale Runtime](../local-runtime.md)
