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
zusätzlich seine Quelle (`image` oder `tensor`) und eine Vorverarbeitung. Ein
Ausgang beschreibt seine fachliche Semantik sowie optionale Nachverarbeitung.

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

`RunModelInference` ist der gemeinsame Anwendungsfall für Cloud und lokal. Er
lädt ein für das Team verfügbares Modell, prüft vorbereitete Eingabe-Tensoren
gegen den Modellvertrag, liest das Artefakt genau einmal und validiert auch die
Tensoren der Runtime-Ausgabe gegen den Ausgangsvertrag.

```text
ModelCatalog + ModelArtifactReader
            ↓
     RunModelInference
            ↓
    ModelInferenceRuntime
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

### Cloud-Runtime

Firebase Functions führt keine Python-/ONNX-Runtime mit sich. Die Cloud-Variante
implementiert deshalb künftig denselben `ModelInferenceRuntime`-Port als
authentifizierten Aufruf eines separaten Inferenzdienstes, etwa auf Cloud Run.
Katalog, Vertrag, Artefakt-Reader und der spätere Modell-Baustein bleiben dabei
unverändert.

## Nächste Schritte

1. Die Transformations-Registry für Bild- und Tensorquellen implementieren.
2. Einen allgemeinen Modell-Inferenz-Baustein konfigurieren und ausführen.
3. Die Cloud-Inferenzruntime sowie die novooa-interne Upload-/Prüfpipeline für
   Systemmodelle ergänzen.

## Verwandt

- [Aufgabe-Ausführung](./aufgabe-ausfuehrung.md)
- [Dateien](./dateien.md)
- [Lokale Runtime](../local-runtime.md)
