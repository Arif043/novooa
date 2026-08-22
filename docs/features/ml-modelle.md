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

## Nächste Schritte

1. Eine Python-/ONNX-Runtime hinter einem einheitlichen Inferenzport anbinden.
2. Einen allgemeinen Modell-Inferenz-Baustein konfigurieren und ausführen.
3. Die novooa-interne Upload-/Prüfpipeline für Systemmodelle ergänzen.

## Verwandt

- [Aufgabe-Ausführung](./aufgabe-ausfuehrung.md)
- [Dateien](./dateien.md)
- [Lokale Runtime](../local-runtime.md)
