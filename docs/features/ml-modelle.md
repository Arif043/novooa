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
- Erwartete Tensoren, Transformationen und Ergebnissemantik verbindlich
  dokumentieren und validieren.
- Das Manifest in Firestore und SQLite identisch persistieren.

## Katalogeintrag

`scope` trennt Modellverfügbarkeit von der technischen Ablage:

- `system`: novooa stellt das Modell allen Teams bereit.
- `team`: später ein teamweit bereitgestelltes Modell. Hochladen durch Nutzer
  ist in der ersten Ausbaustufe noch nicht vorgesehen.

`artifactReference` ist eine logische Referenz. Die technische Distribution
eines globalen Modells liegt separat in der Firestore-Infrastruktur. Die lokale
Runtime lädt das Artefakt direkt mit `@huggingface/hub`, prüft Größe und
SHA-256 und legt danach eine teamgebundene lokale Kopie an. Modellbytes werden
weder über Firestore noch über novooa-Functions proxied.

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
  distribution: {
    type: "huggingFace",
    repository: "organisation/modell",
    revision: "<40-stelliger-commit-hash>",
    path: "model.onnx",
  },
  contract: {inputs: [...], settings: [...], outputs: [...]},
}
```

## Mehrsprachige Manifeste

`title` und `description` sind englisch und gelten als Rückfallsprache. Ein Manifest
kann optional `translations` mit weiteren Sprachen angeben; der Schlüssel ist ein
BCP-47-Sprachcode (`de`, `pt-BR`), der Wert enthält `title`, `description` und
optional `tags`. Ohne `tags` gelten die Tags der Rückfallsprache; übersetzte Tags
folgen denselben Regeln (nicht leer, eindeutig):

```json
"translations": {
  "de": {"title": "SqueezeNet 1.1", "description": "Klassifiziert ein Bild.", "tags": ["bild"]}
}
```

Fehlt eine Sprache, zeigt der Client den englischen Text. Die App ist deutsch und nutzt daher die Übersetzung `de`, sofern vorhanden. Die Auflösung versucht
zuerst den exakten Code, dann die reine Sprache (`pt-BR` → `pt`). Die
Übersetzungen werden mit dem Katalogeintrag in Firestore, SQLite
(`model_catalog.translations_json`) und den lokalen Dateien persistiert. Labels
von Einstellungen und Ausgangsparametern sind noch nicht übersetzbar.

## Manifest

### Typen an den drei Grenzen

Das ML-Feature unterscheidet bewusst drei Typ-Ebenen. Sie dürfen nicht
gleichgesetzt werden:

| Ebene | Zweck | Beispiele |
| --- | --- | --- |
| Workflow-Werttyp | Fachlicher Wert zwischen Bausteinen | `string`, `number`, `boolean`, `json`, `audio` |
| Modellquelltyp | Wert, den eine Modelleingabe vor ihrer Transformation erhält | `text`, `number`, `image`, `audio`, `file`, `datetime`, `boolean`, `json`, `tensor` |
| Tensor-Datentyp | Technische ONNX-Repräsentation an der Inferenzgrenze | `float32`, `int64`, `uint8`, einschließlich Tensorform |

Ein Modellvertrag bildet Modellquelltypen über Transformationen auf
Tensor-Datentypen ab. Ein Workflow-Wert kann dabei direkt als Quelle dienen,
aber beide Ebenen bleiben getrennt. Beispielsweise liefert ein Slider den
fachlichen Wert `number` `1.0`; `tensor.constant` formt ihn z.B. für Kokoro in den
technischen ONNX-Tensor `float32[1]` für die Eingabe `speed` um.

Alle Modelle arbeiten an der Runtime-Grenze mit Tensoren. Ein Eingang beschreibt
zusätzlich seine Quelle (`image`, `audio`, `file`, `text`, `datetime`, `number`,
`boolean`, `json` oder `tensor`) und eine Transformationspipeline. Ein Ausgang beschreibt
seine fachliche Semantik sowie eine optionale Transformationspipeline.

`audio` ist ein fachlicher Workflow-Wert, der immer auf eine gespeicherte
Audiodatei verweist. Sprach-zu-Text-Manifeste deklarieren einen `audio`-Eingang;
Text-zu-Sprache-Manifeste deklarieren einen Workflow-Ausgang vom Typ `audio`.
Die Runtime speichert diesen Ausgang als Team-Datei. Der Baustein
`textToSpeech` und `speechToText` verwenden denselben Vertrag wie
`modelInference`. Ihre Oberflächen filtern den Modellkatalog jeweils auf
Audio-Ausgänge beziehungsweise Audio-Eingänge. `textToSpeech` kann stattdessen
ein verbundenes Sprachmodell verwenden, siehe
[`sprachausgabe.md`](./sprachausgabe.md).

Ein Eingang ist standardmäßig eine feste Workflow-Eingabe des Bausteins. Seine
Zuordnung wird im Arbeitsplan gespeichert und kann ein Template enthalten.
`binding: {type: "derived", inputName: "..."}` leitet denselben Quellwert für
einen weiteren Tensor ab; `binding: {type: "generated", value: ...}` erzeugt
eine technische Quelle aus dem Manifest. Beide erscheinen weder als zusätzliche
Eingabefelder noch als Workflow-Konfiguration. So bleiben etwa Piper-`input_lengths`
und `scales` technische Vertragsdetails.

`settings` ergänzt sichtbare, feste Einstellungen eines Modellbausteins.
Der Modellautor deklariert `slider`, `checkbox` oder `radioGroup` mit Label und
Standardwert. Der Arbeitsplan speichert den jeweils gewählten Wert; ein
Template-Ausdruck ist weiterhin erlaubt. Transformationen referenzieren ihn
mit `$<parametername>`. Damit sind Modellparameter wie Sprechtempo klar
konfigurierbar, ohne versteckte Modelleingaben zu erzeugen.

```ts
settings: [{
  name: "lengthScale",
  label: "Sprechtempo",
  control: {type: "slider", minimum: 0.6, maximum: 1.4, initial: 1, step: 0.01},
}],
inputs: [{
  name: "scales",
  source: "text",
  binding: {type: "generated", value: ""},
  dataType: "float32",
  shape: [3],
  transformations: [{
    type: "tensor.constant",
    parameters: {values: ["$noiseScale", "$lengthScale", "$noiseWidth"]},
  }],
}],
```

```ts
{
  inputs: [{
    name: "image",
    source: "image",
    dataType: "float32",
    shape: ["dynamic", 3, 224, 224],
    transformations: [
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
    transformations: [
      {type: "tensor.softmax", parameters: {axis: -1}},
      {
        type: "tensor.topK",
        result: "topClasses",
        parameters: {
          parameter: {
            name: "k", label: "Anzahl der Ergebnisse",
            default: 3, minimum: 1, maximum: 20,
          },
        },
      },
    ],
    workflowOutput: {
      name: "classifications",
      type: "json",
      mapping: {"$map": {
        from: "topClasses",
        item: {
          index: "$item.index",
          label: {"$lookup": {
            values: ["Klasse A", "Klasse B"], key: "$item.index",
          }},
          score: "$item.value",
        },
      }},
    },
  }],
}
```

`transformations` ist für Ein- und Ausgänge dieselbe deklarative Syntax. Der
Python-Worker verarbeitet sie an beiden Tensorgrenzen: Eingabestrategien erzeugen
Tensoren aus Workflow-Quellen, Ausgabestrategien erzeugen allgemeine
Zwischenwerte. `result` benennt einen solchen Zwischenwert für das
`workflowOutput.mapping`. Python entdeckt Strategien anhand ihrer
Transformationskennung automatisch aus den Eingabe- und Ausgabepaketen. Eine
neue Transformation ergänzt daher nur ihr eigenes Strategie-Modul; Worker,
Registry und vorhandene Strategien bleiben unverändert. TypeScript wertet keine
Transformation aus. Seine Verträge werden über injizierte Fähigkeiten
validiert; das Deployment entscheidet als Composition Root, welche Fähigkeiten
es freigibt. Ihre Ergebnisse bleiben technische Zwischenwerte; erst
`workflowOutput.mapping` definiert den fachlichen Workflow-Wert.

Die Systemmodelle [`piper-de-eva-x-low.json`](../../local-runtime/system-models/piper-de-eva-x-low.json)
und [`piper-de-thorsten-medium.json`](../../local-runtime/system-models/piper-de-thorsten-medium.json)
sind deutsche Text-zu-Sprache-Beispiele. Thorsten in mittlerer Qualität ist für
natürlichere Ausgabe vorgesehen, Eva `x_low` für kleine, schnelle Installationen.
Ihre Manifeste enthalten die für Piper notwendige Phonemzuordnung; die ONNX-Artefakte
werden direkt von Hugging Face geladen.
Die Eingabetransformationen `text.piperPhonemes` und `text.piperPhonemeLength`
bereiten Text für Piper vor, `tensor.constant` erhält die im Baustein konfigurierten Inferenzparameter
und `audio.wav` serialisiert die Wellenform als fachlichen Audio-Ausgabewert.

`tensor.topK` besitzt keinen fest kodierten Wert. Die Beschreibung
unter `parameter` definiert Name, sichtbares Label, Standardwert und erlaubten
Bereich. Der Arbeitsplan speichert ausschließlich den gewählten Wert, etwa
`{outputName: "scores", name: "k", value: 5}`. Damit bleibt ein Plan beim
Update eines Modells validierbar, während der Modellautor die zulässigen Grenzen
kontrolliert.

`workflowOutput` ist kein weiterer Transformationsschritt. Es beschreibt den
fachlichen Workflow-Wert nach der Pipeline. Das Mapping akzeptiert Literale,
Referenzen wie `$topClasses` und `$item.value`, `$map` für Listen sowie
`$lookup` für indizierte Tabellen. Damit bleibt die Ergebnisstruktur im
Manifest statt im Code einer Transformationsstrategie.

## Persistenz

Cloud: `modelCatalog/{modelId}` in Firestore. Lokal: SQLite-Tabelle
`model_catalog` aus Migration `004_model_catalog.sql`. Beide Adapter
implementieren den Domain-Port `ModelCatalog`.

Die lokale Runtime liest den globalen Firestore-Katalog nach der Firebase-
Anmeldung über `GET /v1/ml-models/catalog`. Eine Installation erfolgt über
`POST /v1/ml-models/catalog/:modelId/install`; dabei wird die technische
Distribution geladen, die Prüfsumme verifiziert und der Eintrag in den lokalen
Teamkatalog übernommen. Öffentliche Hugging-Face-Modelle benötigen kein
Betreiber-Token. Ein optionales `HF_TOKEN` dient ausschließlich lokalen,
zugriffsbeschränkten Quellen und wird nicht ausgeliefert.

### Lokale Verwaltung

In den lokalen Einstellungen ist der Tab **Machine Learning** verfügbar. Er
zeigt alle für den lokalen Workspace verfügbaren ONNX-Katalogeinträge. Ein
Import besteht genau aus zwei Dateien: einer Manifest-JSON und der dazugehörigen
ONNX-Datei. Die Runtime erzeugt daraus die Artefakt-Prüfsumme, legt das Artefakt
unter ihrem lokalen Runtime-Root ab und speichert einen teamgebundenen
Katalogeintrag in SQLite. Der Tab und die Endpunkte existieren nicht in der
Cloud-Variante.

```text
GET    /v1/ml-models
GET    /v1/ml-models/catalog
POST   /v1/ml-models/catalog/:modelId/install
POST   /v1/ml-models/imports              { manifest }
PUT    /v1/ml-models/imports/:id/artifact  application/onnx (Binärstream)
DELETE /v1/ml-models/:id
```

Der Client sendet zuerst das kleine Manifest und erhält eine kurzlebige Import-ID. Anschließend überträgt er das ONNX-Artefakt als einzelnen Binärstream per `PUT`. Die Runtime schreibt den Stream direkt in eine temporäre Datei, begrenzt ihn auf 2 GiB und berechnet Größe sowie SHA-256 beim Empfang. Erst wenn der gesamte Stream vorliegt und Manifest und Modellvertrag validiert sind, wird das Artefakt in den Katalog übernommen; die temporäre Datei wird danach entfernt. JSON-Anfragen der Runtime bleiben auf 1 MiB begrenzt.

Lokale Importe gehören immer dem aktiven Team. Vor dem Speichern fragt das
Node-Gateway den privaten Python-Sidecar nach dessen registrierten Ein- und
Ausgabetransformationen. Enthält das Manifest einen unbekannten Typ, lehnt die
Runtime den Import mit einer verständlichen Validierungsmeldung ab. Der
Python-Sidecar bleibt damit die verbindliche Quelle der unterstützten
Transformationen. Importierte Modelle lassen sich aus dem Katalog entfernen;
das unveränderliche Artefakt bleibt bis zu einer späteren Bereinigung im lokalen
Runtime-Speicher erhalten. Systemmodelle sind in der Ansicht erkennbar, aber
dort nicht löschbar.

Artefakte liegen ausschließlich in der Infrastructure unter dem technischen
Pfad `model-artifacts/{artifactId}/versions/{versionId}/model.onnx`. Dieser
Pfad ist kein Bestandteil eines Katalogeintrags oder Workflow-Werts.

## Inferenz

`RunModelInference` führt ein bereits aufgelöstes Modell aus: Es prüft die
vorbereiteten Eingabe-Tensoren gegen das Manifest, liest das Artefakt genau
einmal und validiert auch die Tensoren der Runtime-Ausgabe gegen die
Ausgangsdefinition im Manifest. `RunModelInferenceWithSources` löst davor die Verfügbarkeit
für ein Team auf, validiert die benannten Workflow-Quellen gegen das Manifest, bereitet sie vor
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

Der `modelInference`-Baustein speichert für jede Modelleingabe den
Manifestnamen, ein `workflowMapping` sowie Quelltyp, Tensor-Datentyp und Form.
Im Task Builder wird das Manifest des ausgewählten Katalogmodells geparst: Jeder
Manifest-Eingang erscheint als eigene Reihe mit Name, frei editierbarem
Workflow-Mapping und Datentyp. Das Mapping akzeptiert feste Werte und
Variablen wie `{{eingabe.value}}`. Innerhalb eines `forEach`-eingebetteten Graphen
steht zusätzlich `{{iteration.value}}` und `{{iteration.index}}` zur
Verfügung. Äußere Ergebnisse sind zusätzlich über `{{global.referenz.value}}` und Eingabewerte über `{{global.input.feld}}` verfügbar. Bei einer alleinstehenden Variable übernimmt die Runtime deren
ursprünglichen Wert statt einer Textdarstellung. Kanten
bestimmen weiterhin ausschließlich die Ausführungsreihenfolge. Das Manifest
prüft anschließend Vollständigkeit, Eindeutigkeit und Typ jeder Quelle.
Datei- und Bildwerte lädt der Adapter über den
bestehenden `TeamFileContentReader`; eine Firebase-Storage-Referenz wird nicht
in das Manifest oder an die Runtime weitergereicht. Tensor-Ausgänge werden vor
dem Übergang in den Workflow durch das deklarative `workflowOutput.mapping` in
semantische Modellwerte konvertiert. Technische ONNX-Ausgangsnamen werden nicht
in den Workflow übernommen. Eine SqueezeNet-Ausgabe steht damit
unter `{{modell1.classifications}}` und lautet beispielsweise
`[{index, label, score}]`. Der höchste Treffer ist damit unter
`{{modell1.classifications.0.score}}` erreichbar. Base64 bleibt auf die technische
HTTP-Grenze der Inferenz beschränkt.

Lokal erfüllt `LocalPythonModelInputTransformer` den Port für Eingaben. In
Cloud und lokaler Runtime verarbeitet Python sowohl Eingabe- als auch
Ausgabetransformationen. TypeScript bindet die daraus gewonnenen Werte über
`workflowOutput.mapping` an den Workflow und führt keine Transformation aus.

Aktuell enthält die lokale Runtime konkrete Strategien für Bildquellen und
unveränderte Tensoren. Verträge mit Text-, Zahlen-, Boolean-, JSON- oder
Dateiquellen werden bereits korrekt gebunden und validiert; ihre technische
Umwandlung wird erst durch die jeweils passende zusätzliche Strategie aktiviert.

| Transformation | Parameter | Wirkung |
| --- | --- | --- |
| `image.decode` | `colorSpace`: `rgb`, `rgba`, `grayscale` | Dekodiert und setzt den Farbraum. |
| `image.resize` | `width`, `height`, optional `colorSpace` | Skaliert mit LANCZOS. |
| `image.resizePad` | `width`, `height`, optional `alignment` (`topLeft` oder `center`), `background`, `colorSpace` | Erhält das Seitenverhältnis und füllt bis zur Zielgröße auf. |
| `image.resizeHeightPad` | `height`, optional `width` oder `widthMultiple`, optional `alignment`, `background`, `colorSpace` | Skaliert auf die Zielhöhe. Mit `width` wird bis zur festen Breite aufgefüllt bzw. abgeschnitten; ohne `width` bleibt die Breite dynamisch und kann auf ein Vielfaches aufgefüllt werden. |
| `image.padToMultiple` | `multiple`, optional `background`, `colorSpace` | Füllt rechts und unten bis zu einem Vielfachen auf; Bildkoordinaten bleiben erhalten. |
| `image.crop` | `left`, `top`, `width`, `height` | Schneidet einen achsenparallelen Bildbereich aus. |
| `image.perspectiveCrop` | `points: [x1, y1, ... x4, y4]`, `width`, `height` | Richtet ein Viereck perspektivisch zu einem Bild aus. |
| `tensor.channelOrder` | `order`, etwa `[2, 1, 0]` | Ordnet Farbkanäle über eine vollständige Indexpermutation um. |
| `tensor.layout` | `order`: `channelsFirst`, `channelsLast` | Ordnet HWC und CHW um. |
| `tensor.normalize` | `mean`, `std` | Normalisiert jeden Farbkanal. |
| `tensor.softmax` | optional `axis: -1` | Normalisiert Werte entlang der letzten Tensorachse. |
| `tensor.sigmoid` | keine | Wandelt Logits elementweise in Wahrscheinlichkeiten. |
| `tensor.threshold` | optional `value` (Standard `0.5`) | Wandelt numerische Werte in eine boolesche Maske. |
| `mask.connectedComponents` | optional `minimumPixels` | Liefert Regionen als `{bounds, pixelCount}`; `bounds` enthält `left`, `top`, `width`, `height`. |
| `mask.textRegions` | `threshold`, `minimumPixels`, `minimumScore`, `dilationWidth`, `dilationHeight`, `padding` | Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab. |
| `geometry.mergeRows` | `minimumVerticalOverlap` | Fasst horizontale Textregionen mit ausreichender vertikaler Überlappung zu einer Zeile zusammen. |
| `geometry.scaleBounds` | `scaleX`, `scaleY`, optional `offsetX`, `offsetY` | Rechnet eine Regionsliste vom Maskenraster in Bildkoordinaten zurück. |
| `tensor.nonMaximumSuppression` | `box`-Spalten, `scoreIndex`, optional `scoreThreshold`, `iouThreshold` | Unterdrückt überlappende Erkennungen und liefert `{index, score, box}`. |
| `sequence.ctcGreedyDecode` | `labels`, `blankIndex`, optional `applySoftmax`, `collapseRepeated`, `allowedCharacters` | Dekodiert CTC-Logits in `{text, confidence}`; `allowedCharacters` begrenzt die Auswahl auf ein fachlich zulässiges Alphabet. |
| `tensor.topK` | Parameterbeschreibung für `k`, optional `result` | Liefert allgemeine Paare aus Index und Wert. |
| `workflowOutput.mapping.$map` | `from`, `item` | Formt ein Transformations-Ergebnis zu einer Liste. |
| `workflowOutput.mapping.$lookup` | `values`, `key` | Liest einen Wert aus einer indizierten Tabelle. |

Der Worker fügt bei einem Manifest mit einer Eingabeform wie `["dynamic", 3, 224, 224]` den Batch-
Index hinzu, wenn das Bild zunächst als `[3, 224, 224]` vorliegt. Vor der
Rückgabe prüft er Form, Datentyp und Byte-Länge. Tensorquellen werden zunächst
nur ohne Transformation durchgereicht; weitere Tensorstrategien ergänzen wir
über denselben Port.

### Allgemeine OCR-Pipeline

Ein Texterkennungs-Detektor kann seine Logits ohne modellspezifischen Code in
Regionen überführen:

```ts
transformations: [
  {
    type: "mask.textRegions",
    result: "detectedRegions",
    parameters: {threshold: 0.3, minimumPixels: 8, minimumScore: 0.5},
  },
  {
    type: "geometry.mergeRows",
    result: "regions",
    parameters: {minimumVerticalOverlap: 0.5},
  },
]
```

`mask.textRegions` bildet eine Wahrscheinlichkeitsmaske direkt auf bewertete
Textregionen ab. `geometry.mergeRows` fasst nebeneinander liegende Regionen zu
Lesenzeilen zusammen. Liefert ein Detektor ein kleineres Ausgaberaster, projiziert
`geometry.scaleBounds` die Bounds mit dem bekannten Modell-Stride in
Bildkoordinaten zurück, bevor ein nachfolgender `forEach` sie für `image.crop`
verwendet. Gibt das Modell - wie das verwendete PP-OCRv6-Small-Artefakt - bereits
Koordinaten in der Eingabauflösung aus, wird keine Skalierung ergänzt.

Die konkrete fachliche Form, etwa `{pageRegions: [...]}`, wird danach allein
durch `workflowOutput.mapping` beschrieben. Ein CTC-Textmodell verwendet
`sequence.ctcGreedyDecode`; sein Alphabet und der Leerindex liegen im Manifest.

`image.crop` und `image.perspectiveCrop` sind allgemeine
Transformationen für Bildeingaben. Transformationsparameter können statisch
sein oder einen Ausführungskontext referenzieren. Eine Referenz besteht aus
einem vollständigen `$iteration.value.bounds`-Pfad, etwa für die vom
Detektor gelieferte Region. Werte des äußeren Graphen werden mit
`$global.detektor.value.bounds` referenziert. Die Runtime löst solche Referenzen unmittelbar vor
der Python-Inferenz auf; für das Python-Backend bleiben ausschließlich konkrete
Parameter übrig. So kann ein Manifest dieselbe Crop-Transformation in jeder
Iteration mit anderen Koordinaten ausführen, ohne ein zweites Manifestformat
oder modellspezifische Logik.

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
Cache. Der Sidecar hält unveränderliche Modell-Bundles aus ONNX-Session und
benannten Zusatzressourcen in einem getrennten LRU-Cache. Sein Schlüssel enthält
`artifactId`, `versionId`, die ONNX-Prüfsumme sowie Namen und Prüfsummen aller
Zusatzressourcen. Dadurch wird eine Modellversion nur beim ersten Zugriff einer
warmen Instanz aus Storage geladen und als ONNX-Session initialisiert.

Zusatzressourcen werden vor dem Einfügen in den Cache vollständig dekodiert und
gegen ihre SHA-256-Prüfsumme geprüft. Transformationen erhalten bei Bedarf nur
einen lesenden Zugriff auf deren Bytes, nie einen Dateipfad oder einen
beschreibbaren Cache-Eintrag. Damit können Modelle etwa Stimmen- oder
Vokabular-Dateien verwenden, ohne Seiteneffekte zwischen Ausführungen zu
verursachen.

Eingabe- und Ausgabetransformationen laufen im Python-Sidecar. Dadurch
verwenden sie dieselben Strategieregistries und können dessen Prozesse zwischen
Anfragen wiederverwenden.

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
die ausschließlich Firestore des angegebenen GCP-Projekts verwendet.

```bash
gcloud auth application-default login
npm --prefix functions run models:publish -- \
  --project syscat-90bff \
  --manifest models/mobilenet-v3/model.json \
  --artifact models/mobilenet-v3/model.onnx \
  --dry-run
```

Ohne `--dry-run` registriert die CLI den Katalogeintrag und seine technische
Distribution. Das lokale Artefakt wird dabei nur gegen das Manifest validiert
und gehasht; es wird nicht in Firebase Storage hochgeladen. Die
`distribution` im Manifest ist dafür Pflicht. `--python <pfad>` wählt den
Interpreter für die ONNX-Prüfung; ohne Angabe wird `PYTHON_EXECUTABLE` oder
`python3` verwendet. Die Betreiberidentität benötigt Schreibzugriff auf
`modelCatalog`.

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
  "distribution": {
    "type": "huggingFace",
    "repository": "organisation/mobilenet-v3-onnx",
    "revision": "<40-stelliger-commit-hash>",
    "path": "model.onnx"
  },
  "contract": {
    "inputs": [{
      "name": "input",
      "source": "image",
      "dataType": "float32",
      "shape": ["dynamic", 3, 224, 224],
      "transformations": [
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
      "transformations": []
    }]
  }
}
```

Die CLI validiert Manifest und Modell, prüft das Modell durch das Öffnen einer
ONNX-Runtime-Session und vergleicht Namen, Datentypen sowie statische
Tensorformen mit dem Manifest. Gegenwärtig akzeptiert sie Bild- und
Tensoreingänge, die registrierten Bildtransformationen sowie keine
Ausgangsnachverarbeitung. Anschließend berechnet sie Größe und SHA-256 und
speichert den Firestore-Katalogeintrag zusammen mit der technischen
Distribution. Die Runtime lädt später die durch Commit und Pfad unveränderlich
referenzierte Datei direkt von Hugging Face und verifiziert sie erneut.

## Nächste Schritte

1. Weitere Eingabe- und Ausgangstransformationen als Strategien ergänzen.

## Verwandt

- [Aufgabe-Ausführung](./aufgabe-ausfuehrung.md)
- [Dateien](./dateien.md)
- [Lokale Runtime](../local-runtime.md)
