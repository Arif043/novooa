# ML-Modelle

## Zweck

Das Feature verwaltet einen plattformunabhängigen Katalog klassischer
Machine-Learning-Modelle. In der ersten Ausbaustufe unterstützt novooa ONNX.
Ein Katalogeintrag beschreibt das Modell, seinen logischen Artefaktverweis und
den vollständigen Ein-/Ausgabevertrag; er enthält weder Firebase-Pfade noch
Provider-spezifische Download-URLs.

## Verantwortlichkeiten

- System- und künftig teamweite Modelle über `ModelCatalog` auffindbar machen.
- ONNX-Artefakte über `artifactId` und `versionId` logisch referenzieren und
  vor der Inferenz auf Größe sowie SHA-256 prüfen.
- Erwartete Tensoren, Vorverarbeitung und Ergebnissemantik verbindlich
  dokumentieren und validieren.
- Den Vertrag in Firestore und SQLite identisch persistieren.

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

## Modellvertrag

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

Transformationen verwenden einen offenen Typnamen plus Parameter. Die spätere
Transformations-Registry ordnet jedem Typ eine Strategie zu. Neue Strategien
erfordern daher keine Änderung am Modellvertrag.

## Persistenz

Cloud: `modelCatalog/{modelId}` in Firestore. Lokal: SQLite-Tabelle
`model_catalog` aus Migration `004_model_catalog.sql`. Beide Adapter
implementieren den Domain-Port `ModelCatalog`.

Artefakte liegen ausschließlich in der Infrastructure unter dem technischen
Pfad `model-artifacts/{artifactId}/versions/{versionId}/model.onnx`. Dieser
Pfad ist kein Bestandteil eines Katalogeintrags oder Workflow-Werts.

## Inferenz

`RunModelInference` führt ein bereits aufgelöstes Modell aus: Es prüft die
vorbereiteten Eingabe-Tensoren gegen den Modellvertrag, liest das Artefakt genau
einmal und validiert auch die Tensoren der Runtime-Ausgabe gegen den
Ausgangsvertrag. `RunModelInferenceWithSources` löst davor die Verfügbarkeit
für ein Team auf, ordnet alle Workflow-Quellen dem Vertrag zu, bereitet sie vor
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

## Eingabetransformationen

`PrepareModelInputs` ordnet fachliche Quellen den Eingangsdefinitionen des
Modellvertrags zu. Eine Quelle kann Text, Datum/Uhrzeit, Zahl, Boolean, JSON,
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
der eingehenden Kanten auf Modellquellen. Erst der Modellvertrag prüft Anzahl
und Typ dieser Quellen. Datei- und Bildwerte lädt der Adapter über den
bestehenden `TeamFileContentReader`; eine Firebase-Storage-Referenz wird nicht
in den Modellvertrag oder an die Runtime weitergereicht. Seine primäre Ausgabe
ist JSON mit Modell-ID und Tensoren (`name`, `semantic`, `dataType`, `shape`,
`dataBase64`); beispielsweise ist der erste Tensor über
`{{modell1.value.outputs.0.dataBase64}}` referenzierbar.

Lokal erfüllt `LocalPythonModelInputTransformer` den Port. Sein Worker baut
eine `TransformationRegistry` aus eigenständigen `InputTransformStrategy`-
Klassen zusammen. Neue Transformationen erfordern damit nur eine zusätzliche
Strategieklasse und deren Registrierung im lokalen Composition Root, nicht aber
eine Änderung der Pipeline oder des Modellvertrags.

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

Der Worker fügt bei einem Vertrag wie `["dynamic", 3, 224, 224]` den Batch-
Index hinzu, wenn das Bild zunächst als `[3, 224, 224]` vorliegt. Vor der
Rückgabe prüft er Form, Datentyp und Byte-Länge. Tensorquellen werden zunächst
nur ohne Vorverarbeitung durchgereicht; weitere Tensorstrategien ergänzen wir
über denselben Port.

### Cloud-Runtime

Die Cloud-Inferenz läuft in einem privaten Cloud-Run-Container. Der Container
verwendet denselben Domain-Use-Case `RunModelInferenceWithSources` wie die
lokale Variante, jedoch mit Firestore als `ModelCatalog` und Cloud Storage als
`ModelArtifactReader`. ONNX Runtime und die Transformationsstrategien laufen
im Container in Python. Dadurch bleiben Katalog, Vertrag und Ausführungspfad
identisch; nur die technische Composition unterscheidet sich.

Der HTTP-Adapter nimmt ausschließlich transportierbare Werte entgegen:

```text
POST /v1/inferences
{ teamId, modelId, inputs: [{type, ...}] }
```

Bild- und Dateiquellen enthalten Base64-Bytes, Tensoren enthalten `name`,
`dataType`, `shape` und `dataBase64`. Der Service gibt die vertraglich
validierten Ausgabe-Tensoren im selben portablen Format zurück. Weder die
Anfrage noch der Modellvertrag enthalten Firebase-Pfade.

Das Image entsteht mit:

```bash
docker build -f functions/Dockerfile.model-inference -t novooa-model-inference .
docker run --rm -p 8080:8080 novooa-model-inference
```

Für Cloud Run wird es aus dem Repository-Root gebaut. Der Container hört auf
`0.0.0.0:$PORT`; der Dienst bleibt privat. Die spätere Firebase-Function ruft
ihn mit einem Google-ID-Token und der IAM-Rolle `roles/run.invoker` auf.

Bis dieser Adapter bereitsteht, injiziert der Firebase-Worker einen expliziten
`UnavailableModelInference`-Adapter. Ein Cloud-Run mit
`modelInference` endet deshalb nachvollziehbar mit „Die ONNX-Inferenz ist in
der Cloud noch nicht eingerichtet.“ statt die Bilddaten stillschweigend zu
verwerfen. Der lokale Composition Root wird `RunModelInferenceWithSources` mit den
SQLite-/Dateisystem-Adaptern, dem Python-Transformer und der ONNX-Runtime
verdrahten.

## Nächste Schritte

1. Den authentifizierten Cloud-Run-Client als `ModelInference`-Adapter in der
   Firebase-Function ergänzen.
2. Die novooa-interne Upload-/Prüfpipeline für
   Systemmodelle ergänzen.

## Verwandt

- [Aufgabe-Ausführung](./aufgabe-ausfuehrung.md)
- [Dateien](./dateien.md)
- [Lokale Runtime](../local-runtime.md)
