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
  task: "image-classification",
  languages: [],
  tags: ["leichtgewichtig"],
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

### Aufgabe, Sprachen und Tags

Die Modellsuche filtert nach dem **Was**, nicht nach dem **Wie**: Ob ein Modell
intern eine SVM oder ein CNN nutzt, spielt keine Rolle — entscheidend ist das
Problem, das es löst.

- **`task`** (Pflicht im Manifest): genau eine Aufgabe aus einem festen Vokabular
  (`domain/entities/model-task.ts`). Die Schlüssel folgen überwiegend den
  Pipeline-Tags von Hugging Face; mit ★ markierte sind eigene Ergänzungen. Die App
  ordnet jede Aufgabe fest einem Bereich zu:

  | Bereich | Aufgaben (`task`) |
  | --- | --- |
  | Bild & Video | `image-classification`, `object-detection`, `image-segmentation`, `image-to-text` (Bilder beschreiben), `optical-character-recognition` ★, `document-question-answering` (Dokumente auslesen), `depth-estimation`, `keypoint-detection`, `zero-shot-image-classification`, `image-to-image`, `video-classification` |
  | Audio | `text-to-speech`, `automatic-speech-recognition`, `audio-classification`, `voice-activity-detection`, `speaker-diarization` ★, `audio-to-audio` |
  | Text | `text-classification`, `token-classification`, `translation`, `summarization`, `question-answering`, `zero-shot-classification`, `sentence-similarity`, `text-generation`, `feature-extraction` |
  | Daten & Zeitreihen | `tabular-classification`, `tabular-regression`, `time-series-forecasting`, `anomaly-detection` ★, `clustering` ★ |
  | Sonstige | `other` |

  Unbekannte Werte lehnen Publishing und Import ab. Gespeicherte Einträge von
  vorher gelten als `other` („Sonstige“); unbekannte Schlüssel einer neueren
  Runtime zeigt die App ebenfalls unter „Sonstige“. Neue Aufgaben werden in
  `model-task.ts` (Runtime) und `model_task.dart` samt deutscher Bezeichnung in
  `model_task_label.dart` (App) ergänzt.
- **`languages`** (optional): BCP-47-Codes der unterstützten Sprachen; leer bei
  sprachunabhängigen Modellen (z. B. Bildmodelle).
- **`tags`**: nur noch für Feinheiten (`emotionen`, `hohe-qualitaet`); Aufgabe und
  Sprache gehören nicht in die Tags.

Kann ein Modell mehrere Aufgaben (z. B. transkribieren und übersetzen), bekommt
jede Aufgabe einen **eigenen Katalogeintrag** mit eigenem Vertrag, Titel und
Beschreibung. Die Einträge verweisen auf dieselbe Artefaktversion; die Datei liegt
nur einmal in der Runtime und wird erst entfernt, wenn kein Eintrag sie mehr nutzt.

Der Suchdialog im Aufgabenstudio zeigt Filter-Chips für Aufgabe (Einfachauswahl)
und Sprache (Mehrfachauswahl), jeweils nur mit Treffern und deren Anzahl. Gibt es
Treffer in mehreren Bereichen und mehr als sechs Aufgaben-Chips, erscheint davor
eine Bereichsebene; nach Wahl eines Bereichs zeigt die Aufgabenzeile nur dessen
Aufgaben. Bausteine
mit fester Aufgabe („Text vorlesen“, „Audio transkribieren“) blenden die
Aufgaben-Chips aus. Die Textsuche findet auch die deutschen Bezeichnungen von
Aufgabe und Sprache. SQLite speichert beides in `model_catalog.task` und
`model_catalog.languages_json` (Migration `0021_model_catalog_task.sql`).

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
von Einstellungen sind noch nicht übersetzbar.

## Manifest

### Typen an den drei Grenzen

Das ML-Feature unterscheidet bewusst drei Typ-Ebenen. Sie dürfen nicht
gleichgesetzt werden:

| Ebene | Zweck | Beispiele |
| --- | --- | --- |
| Workflow-Werttyp | Fachlicher Wert zwischen Bausteinen | `string`, `number`, `boolean`, `json`, `audio`, `image` (im Workflow ein Bild-`media`-Wert) |
| Modellquelltyp | Wert, den eine Modelleingabe vor ihrer Transformation erhält | `text`, `number`, `image`, `audio`, `file`, `datetime`, `boolean`, `json`, `tensor` |
| Tensor-Datentyp | Technische ONNX-Repräsentation an der Inferenzgrenze | `float32`, `float16`, `float64`, `int64`, `int32`, `int16`, `int8`, `uint8`, `bool`, `string`, einschließlich Tensorform. `string`-Tensoren reisen als UTF-8-JSON-Array ihrer Werte in Zeilenfolge. |

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
Analog speichert ein Workflow-Ausgang vom Typ `image` (Ergebnis von `image.encode`) eine
Bilddatei als Team-Datei; nachfolgende Bausteine erhalten sie als Bild (`media`).
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
        parameters: {k: "$anzahl"},
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

**Einstellbare Werte sind Settings.** Im Beispiel ist `k` nicht fest kodiert, sondern
an das Setting `anzahl` gebunden. Dazu deklariert der Vertrag:

```ts
settings: [{
  name: "anzahl", label: "Anzahl der Ergebnisse",
  control: {type: "slider", initial: 3, minimum: 1, maximum: 20, step: 1},
}],
```

- Der Baustein zeigt das Setting unter den Modelleinstellungen und speichert nur den
  gewählten Wert (`settings: [{name: "anzahl", valueTemplate: "5"}]`).
- Vor dem Lauf ersetzt die Runtime jedes `"$anzahl"` in Ein- und Ausgangsparametern
  durch diesen Wert (`resolveModelContractBindings`). Transformationen wissen von
  Settings nichts.
- Der Modellautor kontrolliert Grenzen und Standardwert, und ein Plan bleibt beim
  Update eines Modells validierbar.

**Ältere Manifeste und Aufgaben** nutzten dafür eine Parameterbeschreibung
(`parameters: {parameter: {name, label, default, minimum, maximum}}`) und speicherten
Werte als `outputParameters`. Beides wird beim Lesen automatisch umgewandelt:
- Die Beschreibung wird zu einem Slider-Setting `<ausgang>_<name>`
  (`legacy-output-parameter-settings.ts`).
- Gespeicherte Werte werden zu Settings gleichen Namens (`legacy-model-output-parameters.ts`
  in der Runtime, `legacy_model_output_parameters.dart` in der App).
- Ohne Bindung nutzt `tensor.topK` den Standardwert der alten Beschreibung.

`workflowOutput` ist kein weiterer Transformationsschritt. Es beschreibt den
fachlichen Workflow-Wert nach der Pipeline. Das Mapping akzeptiert Literale,
Referenzen wie `$topClasses` und `$item.value`, `$map` für Listen sowie
`$lookup` für indizierte Tabellen. Damit bleibt die Ergebnisstruktur im
Manifest statt im Code einer Transformationsstrategie.

## Persistenz

Cloud: `modelCatalog/{modelId}` in Firestore. Lokal: SQLite-Tabelle
`model_catalog` aus Migration `004_model_catalog.sql`. Beide Adapter
implementieren den Domain-Port `ModelCatalog`.

`FirestoreModelCatalog` implementiert zusätzlich den Port `SystemModelCatalog`
(`listSystemEntries`), für Aufrufer ohne Team-Bezug. Der Use Case
`SearchModelCatalog` sucht mit `ModelSearchCriteria` (Aufgabe, Sprachen,
Suchbegriffe, Limit ≤ 20). Ohne Team sucht er nur im globalen Katalog, sonst in
System- und Team-Modellen. Sprachunabhängige Modelle passen zu jeder Sprache.
Treffer werden nach der Zahl passender Suchbegriffe in ID, Titel, Beschreibung,
Aufgabe, Tags und Übersetzungen sortiert. Ihn nutzt das Tool `sucheModelle` des
[KI-Agenten](./ki-agent.md#multiagenten-architektur-aufgabenstudio).

Der globale Firestore-Katalog ist die **primäre Quelle** für ONNX-Modelle. Die
lokale Runtime liest ihn nach der Firebase-Anmeldung über
`GET /v1/ml-models/catalog` (ohne Firebase-Sitzung: `503`). Sie installiert
Katalogmodelle nicht vorab, sondern **cacht** sie, sobald sie gebraucht werden:

- **Auswahl im Aufgabenstudio:** Wählt man in einem ML-Baustein ein Modell aus dem
  Katalog, startet `POST /v1/ml-models/catalog/:modelId/cache` den Download im
  Hintergrund (`202`; `200`, wenn es schon lokal ist). Der Fortschritt steht unter
  `GET /v1/ml-models/cache-status` (`downloading` oder `failed` mit Meldung);
  Änderungen meldet das Realtime-Thema `model-cache`, das fertige Modell
  zusätzlich `model-catalog`.
- **Beim Lauf:** Fehlt ein Modell lokal, etwa nach dem Import einer Aufgabe oder
  nachdem es aus dem Cache entfernt wurde, lädt der Lauf es vor der Inferenz nach
  (`SelfCachingModelCatalog`). Gleichzeitige Anfragen für dasselbe Modell teilen
  sich einen Download (`CacheSystemModel`).

Beim Cachen werden die technische Distribution geladen, Größe und SHA-256 geprüft,
der Modellvertrag gegen den Python-Sidecar validiert und der Eintrag als
teamgebundener Eintrag mit `origin = catalog` gespeichert. Gecachte Modelle bleiben,
bis sie manuell entfernt werden; es gibt keine automatische Bereinigung. Der
Download-Status lebt nur im Speicher; nach einem Neustart zählt, was im Katalog
steht. Öffentliche Hugging-Face-Modelle benötigen kein Betreiber-Token. Ein
optionales `HF_TOKEN` dient ausschließlich lokalen, zugriffsbeschränkten Quellen
und wird nicht ausgeliefert.

### Lokale Verwaltung

In den lokalen Einstellungen ist der Tab **Machine Learning** verfügbar. Er zeigt
zwei Abschnitte: **Gecachte Modelle** (`origin = catalog`, mit Größe, laufenden
oder gescheiterten Downloads und „Aus dem Cache entfernen“) und **Eigene Modelle**
(`origin = import`). Den Katalog selbst durchsucht man im Aufgabenstudio, nicht in
den Einstellungen. Die SQLite-Spalte `model_catalog.origin` (Migration
`0020_model_catalog_origin.sql`) unterscheidet beide Herkünfte; ältere Einträge
gelten als Import.

Ein eigener Import besteht genau aus zwei Dateien: einer Manifest-JSON und der
dazugehörigen ONNX-Datei. Die Runtime erzeugt daraus die Artefakt-Prüfsumme, legt
das Artefakt unter ihrem lokalen Runtime-Root ab und speichert einen
teamgebundenen Katalogeintrag in SQLite. Eigene Modelle erscheinen auch in der
Modellsuche des Aufgabenstudios. Der Tab und die Endpunkte existieren nicht in
der Cloud-Variante.

```text
GET    /v1/ml-models                         gecachte und eigene Modelle (mit origin)
GET    /v1/ml-models/catalog                 globaler Katalog (503 ohne Firebase-Sitzung)
POST   /v1/ml-models/catalog/:modelId/cache  Hintergrund-Download starten
GET    /v1/ml-models/cache-status            laufende und gescheiterte Downloads
POST   /v1/ml-models/imports                 { manifest }
PUT    /v1/ml-models/imports/:id/artifact    application/onnx (Binärstream)
DELETE /v1/ml-models/:id                     aus dem Cache entfernen / Import löschen
```

Der Client sendet zuerst das kleine Manifest und erhält eine kurzlebige Import-ID. Anschließend überträgt er das ONNX-Artefakt als einzelnen Binärstream per `PUT`. Die Runtime schreibt den Stream direkt in eine temporäre Datei, begrenzt ihn auf 2 GiB und berechnet Größe sowie SHA-256 beim Empfang. Erst wenn der gesamte Stream vorliegt und Manifest und Modellvertrag validiert sind, wird das Artefakt in den Katalog übernommen; die temporäre Datei wird danach entfernt. JSON-Anfragen der Runtime bleiben auf 1 MiB begrenzt.

Lokale Importe gehören immer dem aktiven Team. Vor dem Speichern lässt das
Node-Gateway den privaten Python-Sidecar den Modellvertrag prüfen
(`POST /v1/contract-validations`). Enthält das Manifest einen unbekannten Typ oder
passen die Wertarten einer Pipeline nicht zusammen, lehnt die Runtime den Import mit
einer verständlichen Validierungsmeldung ab. Der
Python-Sidecar bleibt damit die verbindliche Quelle der unterstützten
Transformationen. Beim Entfernen eines gecachten oder eigenen Modells löscht die
Runtime auch dessen Artefaktdateien, sofern kein anderer Eintrag dieselbe
Artefaktversion nutzt. Aufgaben mit einem entfernten Katalogmodell laden es beim
nächsten Lauf erneut; ein entferntes eigenes Modell steht nicht mehr zur
Verfügung.

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

Aktuell enthält die lokale Runtime konkrete Strategien für Bild-, Audio-,
Text-, Zahlen-, JSON- und Boolean-Quellen sowie unveränderte Tensoren. Verträge mit Text-, Zahlen-, Boolean-, JSON- oder
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
| `image.perspectiveCrop` | `points` (`[x1, y1, … x4, y4]`), `width`, `height` | Richtet ein Viereck perspektivisch zu einem Bild aus. |
| `tensor.channelOrder` | `order`, etwa `[2, 1, 0]` | Ordnet Farbkanäle über eine vollständige Indexpermutation um. |
| `tensor.layout` | `order`: `channelsFirst`, `channelsLast` | Ordnet HWC und CHW um. |
| `tensor.normalize` | `mean`, `std` | Normalisiert jeden Farbkanal. |
| `tensor.softmax` | optional `axis` (nur `-1`) | Normalisiert Werte entlang der letzten Tensorachse. |
| `tensor.sigmoid` | keine | Wandelt Logits elementweise in Wahrscheinlichkeiten. |
| `tensor.threshold` | optional `value` (Standard `0.5`) | Wandelt numerische Werte in eine boolesche Maske. |
| `mask.connectedComponents` | optional `minimumPixels` | Liefert Regionen als `{bounds, pixelCount}`; `bounds` enthält `left`, `top`, `width`, `height`. |
| `mask.textRegions` | `threshold`, `minimumPixels`, `minimumScore`, `dilationWidth`, `dilationHeight`, `padding` | Leitet aus einer Wahrscheinlichkeitsmaske bewertete Textregionen ab. |
| `geometry.mergeRows` | `minimumVerticalOverlap` | Fasst horizontale Textregionen mit ausreichender vertikaler Überlappung zu einer Zeile zusammen. |
| `geometry.scaleBounds` | `scaleX`, `scaleY`, optional `offsetX`, `offsetY` | Rechnet eine Regionsliste vom Maskenraster in Bildkoordinaten zurück. |
| `tensor.nonMaximumSuppression` | `box`-Spalten, `scoreIndex`, optional `scoreThreshold`, `iouThreshold` | Unterdrückt überlappende Erkennungen und liefert `{index, score, box}`. |
| `sequence.ctcGreedyDecode` | `labels`, `blankIndex`, optional `applySoftmax`, `collapseRepeated`, `allowedCharacters` | Dekodiert CTC-Logits in `{text, confidence}`; `allowedCharacters` begrenzt die Auswahl auf ein fachlich zulässiges Alphabet. |
| `tensor.topK` | `k` (Zahl oder Setting-Bindung wie `"$anzahl"`), optional `result`; veraltet `parameter` (wird beim Lesen zu einem Setting) | Liefert die `k` größten Werte als Paare aus Index und Wert. |
| `datetime.features` | `features` (Liste aus `year`, `month`, `day`, `weekday`, `hour`, `minute`, `second`, `dayOfYear`, `epochSeconds`), optional `cyclic`, `timeZone` | Eingang (Datum/Uhrzeit). Zerlegt einen Zeitpunkt in Zahlenmerkmale; `weekday` zählt ab Montag = 0. Mit `cyclic: true` werden Monat, Wochentag, Stunde, Minute und Jahrestag als sin/cos-Paar kodiert, sodass z. B. 23 Uhr und 0 Uhr nah beieinander liegen. `timeZone` (IANA, z. B. `Europe/Berlin`) wählt die Zählzeitzone, Standard UTC. |
| `image.exifTranspose` | keine | Eingang. Dreht Fotos gemäß EXIF-Ausrichtung (z. B. Handyaufnahmen); vor anderen Bildtransformationen einsetzen. |
| `image.resizeShorterSide` | `size` | Eingang. Skaliert die kürzere Seite auf `size`, das Seitenverhältnis bleibt. |
| `image.centerCrop` | `width`, `height` | Eingang. Schneidet einen Ausschnitt aus der Bildmitte; größer als das Bild ist ein Fehler. Mit `image.resizeShorterSide` die übliche Vorverarbeitung vieler Bildmodelle. |
| `number.toTensor` | keine | Eingang. Macht aus einer Zahl oder Zahlenliste einen eindimensionalen `float32`-Tensor. |
| `tensor.scale` | optional `factor` (Standard `1`), `offset` (Standard `0`) | Ein- und Ausgang. Berechnet `wert × factor + offset`, z. B. `1/255` für Pixel oder zum Zurückrechnen normierter Ausgaben. |
| `tensor.clip` | `min` und/oder `max` | Ein- und Ausgang. Begrenzt Werte auf einen Bereich. |
| `tensor.reshape` | `shape` (positive Zahlen, höchstens einmal `-1`) | Ein- und Ausgang. Formt den Tensor um; die Anzahl der Werte muss passen. |
| `tensor.transpose` | `axes` (vollständige Permutation) | Ein- und Ausgang. Ordnet Achsen um. Für Farbkanäle von Bildern bleibt `tensor.layout` vorzuziehen, weil `tensor.normalize` dessen Layout kennt. |
| `tensor.argmax` | optional `axis` (Standard `-1`) | Ausgang. Index des größten Werts, z. B. die wahrscheinlichste Klasse. |
| `tensor.squeeze` | keine | Ausgang. Entfernt Dimensionen der Größe 1 (etwa die Batch-Dimension). |
| `tensor.reduce` | `operation` (`mean`, `sum`, `max`, `min`), optional `axis` | Ausgang. Verdichtet eine Achse, z. B. Token-Embeddings per Mittelwert zu einem Satzvektor. |
| `tensor.l2Normalize` | optional `axis` | Ausgang. Skaliert Vektoren auf Länge 1 für Ähnlichkeitsvergleiche; Nullvektoren bleiben unverändert. |
| `tensor.slice` | `start`, optional `end`, `axis` | Ausgang. Wählt einen Bereich entlang einer Achse; ein leerer Bereich ist ein Fehler. |
| `tensor.round` | optional `decimals` (Standard `0`) | Ausgang. Rundet auf Nachkommastellen. |
| `tensor.fitLength` | `length`, optional `axis` (Standard `-1`), `value` (Standard `0`), `keep` (`start` oder `end`) | Ein- und Ausgang. Füllt eine Achse auf oder kürzt sie; `keep: end` behält die jüngsten Werte (Zeitreihen-Fenster). |
| `audio.mono` | keine | Eingang (Audio). Mischt alle Kanäle zu einem. |
| `audio.resample` | `sampleRate` | Eingang (Audio). Ändert die Abtastrate per Fourier-Resampling, z. B. auf 16 kHz. |
| `audio.normalize` | optional `mode` (`peak` oder `rms`), `target` (Standard `1` bzw. `0.1`) | Eingang (Audio). Gleicht die Lautstärke an; Stille bleibt unverändert. |
| `audio.fitDuration` | `seconds`, optional `keep` | Eingang (Audio). Füllt mit Stille auf oder kürzt auf eine feste Dauer. |
| `audio.melSpectrogram` | optional `frameLength` (400), `hopLength` (160), `melBins` (80), `minFrequency`, `maxFrequency`, `power` (2), `scale` (`power`, `log`, `log10`, `db`), `dynamicRange`, `melScale` (`slaney`, `htk`), `filterNormalization` (`slaney`, `none`), `center` (`true`) | Eingang (Audio). Liefert ein Mel-Spektrogramm `[melBins, Frames]` aus Mono-Audio. `db` ist relativ zum Maximum; `dynamicRange` begrenzt den Abstand zum Maximum in der gewählten Einheit. Voreinstellungen entsprechen librosa. |
| `json.toTensor` | keine | Eingang (JSON/Boolean). Zahlen und Wahrheitswerte → `float32`-Tensor, Texte → String-Tensor, jeweils auch als gleich lange (verschachtelte) Listen. Gemischte Listen sind ein Fehler. |
| `text.piperPhonemes` | `language`, `phonemeIdMap` | Eingang (Text). Text → Piper-Phonem-IDs mit Start- und Endsymbol (espeak). |
| `text.piperPhonemeLength` | `language`, `phonemeIdMap` | Eingang (Text). Anzahl der Piper-Phonem-IDs, für den zweiten Modelleingang. |
| `text.kokoroTokens` | `language`, `tokenIdMap` | Eingang (Text). Text → Kokoro-Token-IDs, eingerahmt von Füll-Tokens. |
| `text.kokoroStyle` | `language`, `tokenIdMap`, `voice`, `resource` | Eingang (Text). Stilvektor der Stimme `voice` aus der Modellressource `resource`, passend zur Tokenanzahl. |
| `tensor.constant` | `values` | Ersetzt den Wert durch einen festen Zahlentensor, z. B. für Hilfseingänge mit Inferenzparametern. |
| `geometry.toSource` | `input`, optional `clip` (Standard `true`) | Ausgang (Regionen/Erkennungen). Rechnet `bounds` bzw. `box` mit der Geometrie des Bildeingangs `input` in Koordinaten des Originalbildes zurück; `clip` begrenzt auf das Bild. |
| `mask.toSource` | `input`, optional `layout` (`channelsFirst`, `channelsLast`), `fill` (Standard `0`) | Ausgang. Bildet eine Maske oder Karte `[H, W]`, `[C, H, W]` bzw. `[H, W, C]` per Nearest-Neighbour auf die Originalgröße ab; Rand des Modellbildes wird zu `fill`. |
| `image.encode` | optional `format` (`png`, `jpeg`), `fileName`, `layout` (Standard `channelsLast`), `palette` (Liste von `[r, g, b]`) | Ausgang. Kodiert einen Tensor als Bilddatei (Werte auf 0…255 begrenzt); mit `palette` werden Klassenindizes eingefärbt. Workflow-Typ `image`. |
| `resource.lookup` | `resource`, optional `format` (`lines` oder `json`), `key` (Standard `index`), `field` (Standard `label`) | Ausgang (Top-K-Treffer, Erkennungen). Ergänzt jeden Eintrag um seinen Namen aus einer Label-Datei des Modells (`artifactReference.resources`): eine Zeile je Label oder eine JSON-Liste. Große Label-Listen stehen so nicht im Manifest. |
| `audio.wav` | `sampleRate`, optional `fileName` (Standard `sprach-ausgabe.wav`) | Ausgang. Kodiert Samples als WAV-Datei (16 Bit, mono); Werte außerhalb von -1…1 werden begrenzt. |
| `text.toTensor` | keine | Eingang (Text). Text → String-Tensor `[1]`, z. B. für Pipelines mit eingebauter Textverarbeitung (TF-IDF). |
| `json.features` | `features` (Liste aus `{field, kind?, mean?, std?, default?, categories?, unknown?}`) | Eingang (JSON). Datensatz → Merkmalsvektor in fester Reihenfolge; `field` als Punktpfad, `kind` `number` (standardisiert mit `mean`/`std`), `boolean` oder `category` (One-Hot, unbekannte Werte `zero` oder `error`). Eine Liste von Datensätzen ergibt eine Zeile je Datensatz. |
| `sequence.segments` | `frameDuration` oder `hopLength` + `sampleRate`, optional `threshold`, `labels`, `backgroundIndex`, `mergeGap`, `minDuration` | Ausgang. Frame-Scores → Zeitabschnitte `{start, end, score}`; Klassenscores (Frames × Klassen) → `{start, end, index, label?, score}` je wahrscheinlichster Klasse. Zeiten in Sekunden, Werte auf 6 Stellen gerundet. |
| `workflowOutput.mapping.$map` | `from`, `item` | Formt ein Transformations-Ergebnis zu einer Liste. |
| `workflowOutput.mapping.$lookup` | `values` (Liste oder Referenz wie `"$classes"`), `key` | Liest einen Wert aus einer indizierten Tabelle. |
| `workflowOutput.mapping.$outputs` | `$outputs.<ausgang>.<wert>` | Liest den Endwert (`tensor`) oder ein benanntes Ergebnis eines anderen Ausgangs. |

Der Worker fügt bei einem Manifest mit einer Eingabeform wie `["dynamic", 3, 224, 224]` den Batch-
Index hinzu, wenn das Bild zunächst als `[3, 224, 224]` vorliegt. Vor der
Rückgabe prüft er Form, Datentyp und Byte-Länge. Tensorquellen werden zunächst
nur ohne Transformation durchgereicht; weitere Tensorstrategien ergänzen wir
über denselben Port.

**Eingangsquellen im Python-Worker:** `image` (beim Empfang mit Pillow
geöffnet), `audio` (WAV beim Empfang dekodiert: PCM 8/16/24/32 Bit, Float 32/64
Bit, WAVE_EXTENSIBLE; andere Formate wie MP3 werden mit Meldung abgelehnt), `text`,
`number`, `json`, `boolean` und `datetime`. Audio liegt intern als Samples
`(Frames, Kanäle)` vor; Audio-Transformationen stehen vor Tensoroperationen.
Ohne Spektrogramm wird daraus bei Mono ein Tensor `[Samples]`, sonst
`[Kanäle, Samples]`. Alle diese Quellen erreichen Python in Cloud und Standalone-Runtime
gleichermaßen. `datetime` wird als ISO-8601-Zeitpunkt gelesen (ohne Versatz
als UTC). `file` lehnt die Runtime schon beim Import mit Nennung des Quelltyps ab.

**Aufbau des Python-Dienstes.** Alle Transformationen bilden **einen Katalog**, geordnet
nach Fachbereich statt nach Richtung. Die Richtung ergibt sich allein aus der Position in
der Pipeline:

```text
novooa_ml/transformations/        Katalog und Kern
  strategy.py  registry.py  context.py  values.py  parameters.py  discovery.py
  kinds.py          Wertarten
  pipeline_check.py Prüfung der Wertarten-Kette (und der Parameter beim Import)
  parameter_check.py, schema/   Parameterschemas und ihre Prüfung
  image/ audio/ text/ data/ temporal/ tensor/ vision/ sequence/ resources/   eine Strategie je Datei
novooa_ml/model_input/    Grenze zum Modell: Quelle → Pipeline → Tensor (worker, sources, wav_decoder)
novooa_ml/model_output/   Grenze zum Modell: Modellausgang → Pipeline → Ergebnisse (worker)
```

**Wertarten.** Jede Strategie deklariert, welche Arten sie annimmt (`accepts`) und welche
sie liefert (`produces`):

| Wertart | Entsteht durch | Beispiele für Schritte, die sie annehmen |
| --- | --- | --- |
| `image` | Quelle `image`, `image.*` | `image.*`, Tensorschritte (implizit) |
| `audio` | Quelle `audio`, `audio.mono` … | `audio.*`, Tensorschritte (implizit) |
| `text` | Quelle `text` | `text.piper*`, `text.kokoro*` |
| `datetime` | Quelle `datetime` (ISO 8601, ohne Versatz als UTC) | `datetime.features` |
| `number` / `json` | Quellen `number` bzw. `json`/`boolean` | `number.toTensor` bzw. `json.toTensor`, `json.features` |
| `tensor` | Modellausgang, `audio.melSpectrogram`, `text.*`, `json.*`, `tensor.*` | alle `tensor.*`, `mask.*`, `sequence.*`, `audio.wav` |
| `regions` | `mask.connectedComponents`, `mask.textRegions` | `geometry.mergeRows`, `geometry.scaleBounds`, `geometry.toSource` |
| `detections` | `tensor.nonMaximumSuppression` | `geometry.toSource`; sonst Ende der Kette |
| `imageFile` | `image.encode` | Ende der Kette; Workflow-Typ `image` |
| `json-result` | `tensor.topK`, `tensor.nonMaximumSuppression`, `sequence.*` | Ende der Kette; weiter über das Workflow-Mapping |
| `audioFile` | `audio.wav` | Ende der Kette; Workflow-Typ `audio` |

**Kettenregeln.**
- Ein Eingang beginnt mit der Art seiner Quelle und muss bei `tensor` enden. `image` und
  `audio` gelten dabei als Tensor; sie werden ohne eigenen Schritt umgewandelt.
- Ein Ausgang beginnt bei `tensor` und darf mit jeder Art enden.
- `tensor.constant` nimmt jede Art an.
- Quellen vom Typ `tensor` gehen unverändert ans Modell und erlauben keine Transformationen.

Jede Transformation ist damit **in beiden Richtungen** nutzbar, wenn die Wertart passt,
z. B. `tensor.layout` und `tensor.normalize` auch am Ausgang eines Bildmodells. Die
Bezeichnungen „Eingang“ und „Ausgang“ in der Tabelle oben nennen nur den typischen
Einsatz.

**Prüfung beim Import und vor jedem Lauf.**
- Beim Import und Cachen ruft `PythonModelContractValidator` den Endpunkt
  `POST /v1/contract-validations` mit `{contract}` auf. Die Runtime prüft je Ein- und Ausgang:
  1. **Kette:** Passen die Wertarten zusammen? *„Eingang bild: audio.melSpectrogram erwartet
     audio, erhält image.“*
  2. **Parameter** gegen das Schema der Transformation:
     - fehlend: *„Eingang bild: image.resize: Der Parameter width fehlt.“*
     - unbekannt, mit Vorschlag bei Tippfehlern: *„… tensor.nonMaximumSuppression: Unbekannter
       Parameter iouTreshold — gemeint ist vermutlich iouThreshold.“*
     - falscher Typ oder Bereich, auch verschachtelt: *„… tensor.topK: k erwartet eine ganze Zahl
       ≥ 1, erhält 0.“*, *„… box.right erwartet …“*
  3. **Setting-Bindungen** (`"$name"`): Das Steuerelement muss zum Parameter passen. Ein Slider
     braucht passende Grenzen (bei ganzen Zahlen auch eine ganzzahlige Schrittweite), eine
     Checkbox passt nur zu Wahrheitswerten, eine Auswahl nur, wenn jede Option gültig ist.
     *„… tensor.topK: k ist an das Setting anzahl (Checkbox) gebunden, erwartet wird eine ganze
     Zahl ≥ 1.“* Bindungen an Workflow-Werte (`$iteration.value.bounds.left`) sind erst zur
     Laufzeit bekannt und werden nicht geprüft.
- Vor jeder Pipeline prüfen die Worker die Kette. Die Parameter prüfen die Strategien zur
  Laufzeit weiterhin selbst, ebenso Abhängigkeiten zwischen Parametern (z. B. `min ≤ max`).
- `GET /v1/transformation-capabilities` liefert alle Typen und je Typ `{accepts, produces}`
  sowie das Parameterschema (`type`, `optional`, `default`, Grenzen, Optionen, Felder).

**Parameterschemas.** Jede Strategie deklariert neben `accepts`/`produces` ihre Parameter mit
den Bausteinen aus `transformations/schema/`: `Integer`, `Number`, `Boolean`, `Text`,
`Choice`, `ListOf`, `Record` (feste Felder, unbekannte sind ein Fehler), `MapOf` und `OneOf`.
Beispiel:

```python
parameters = {
    "width": Integer(minimum=1),
    "height": Integer(minimum=1),
    "colorSpace": Choice("rgb", "rgba", "grayscale", optional=True),
}
```

**Weitere Regeln.**
- Neue Strategien werden automatisch gefunden: eine nicht abstrakte Unterklasse von
  `TransformationStrategy` mit `accepts`/`produces` in einem Bereichsordner.
- `tests/test_transformation_architecture.py` sichert die Regeln „eine Strategie je
  Datei“ und „Ordner nach Bereich“, die Wertarten, den Typ-Snapshot und die Schemas ab: Jeder
  Parameter, den eine Strategie liest, muss deklariert sein, und die Transformationstabelle
  dieser Doku muss jeden Typ mit allen Parametern nennen.
  `tests/test_pipeline_check.py` prüft u. a. die mitgelieferten Systemmodell-Manifeste.
- Die Cloud-Runtime pflegt ihre Bildtransformationen weiterhin als feste Liste in
  `model-contract-capabilities.ts` und kennt die neueren Typen noch nicht.

### Bildausgaben und Originalkoordinaten

Erkennungs-, Segmentierungs- und Tiefenmodelle rechnen auf einem skalierten oder aufgefüllten
Bild. Damit ihre Ergebnisse zum Originalbild passen, zeichnet jeder Bildeingang seine
**Geometrie** auf: `modell = quelle × scale + offset` je Achse, dazu die Größe des Quellbildes.

| Schritt | Wirkung auf die Geometrie |
| --- | --- |
| `image.resize`, `image.resizeShorterSide` | skaliert |
| `image.resizePad`, `image.resizeHeightPad` | skaliert und verschiebt (Rand) |
| `image.crop`, `image.centerCrop` | verschiebt |
| `image.decode`, `image.padToMultiple`, Tensorschritte | keine |
| `image.exifTranspose` | das gedrehte Foto wird zur Quelle |
| `image.perspectiveCrop` | nicht umkehrbar |

- Die Geometrie reist im Eingangstensor (`metadata`) durch die Runtime bis zu den Ausgängen.
- `geometry.toSource` rechnet Boxen und Regionen, `mask.toSource` Masken und Karten ins
  Originalbild zurück; `input` nennt den Bildeingang.
- Tensorschritte, die am Eingang die räumliche Form ändern (`tensor.reshape`, `tensor.transpose`,
  `tensor.slice`), sind in der Geometrie nicht berücksichtigt.

Objekterkennung mit einem Detektor, der Zeilen `[links, oben, rechts, unten, score]` im
640er-Raster liefert (Eingang mit `image.resizePad` auf 640×640, mittig):

```json
"transformations": [
  {"type": "tensor.squeeze", "parameters": {}},
  {"type": "tensor.nonMaximumSuppression", "parameters": {
    "box": {"left": 0, "top": 1, "right": 2, "bottom": 3}, "scoreIndex": 4, "scoreThreshold": 0.25}},
  {"type": "geometry.toSource", "parameters": {"input": "bild"}}
]
```

Segmentierung als Bild (Klassen eingefärbt, in Originalgröße):

```json
"transformations": [
  {"type": "tensor.argmax", "parameters": {"axis": 1}},
  {"type": "mask.toSource", "parameters": {"input": "bild"}},
  {"type": "image.encode", "parameters": {"palette": [[0, 0, 0], [255, 0, 0], [0, 128, 255]]}}
],
"workflowOutput": {"name": "segmente", "type": "image", "mapping": "$tensor"}
```

### Klassisches ML (scikit-learn, XGBoost, LightGBM)

Modelle aus `skl2onnx` oder `onnxmltools` lassen sich ohne neuen Code anbinden:

- **Datentypen:** Text- und Kategoriespalten sind `string`-Tensoren. Ein Datensatz
  `{"land": "CH", "umsatz": 88}` wird z. B. mit `json.toTensor` (Textspalte als
  `[["CH"]]`) und `json.features` (Zahlenspalten) auf die benannten Modelleingänge
  verteilt. Passen Texte oder Zahlen nicht zum Datentyp im Vertrag, nennt die Runtime
  Eingang und erwarteten Typ.
- **ZipMap:** `skl2onnx` liefert Klassenwahrscheinlichkeiten standardmäßig als Liste von
  Dictionaries. Die Runtime macht daraus einen `float32`-Tensor `[N, Klassen]` (Spalten in
  Klassenreihenfolge) und stellt die Klassen zusätzlich als `$classes` bereit. Der Vertrag
  deklariert den Ausgang als `float32`, z. B. mit Form `["dynamic", "dynamic"]`.
  `zipmap=False` beim Export funktioniert ebenso.
- **Mapping über Ausgänge:** Jedes Workflow-Mapping sieht über
  `$outputs.<ausgang>.<wert>` die Werte der anderen Ausgänge (`tensor` oder benannte
  Ergebnisse). `outputs` ist als Ergebnisname reserviert.
- **`$lookup` mit Referenz:** `values` darf statt einer Liste eine Referenz sein, z. B.
  `{"$lookup": {"values": "$classes", "key": "$index"}}`.

Beispiel eines Klassifikators mit Text-Klassen (`LogisticRegression`, ZipMap):

```json
"outputs": [
  {"name": "output_label", "dataType": "string", "shape": ["dynamic"],
   "semantic": "classification.label", "transformations": [],
   "workflowOutput": {"name": "klasse", "type": "string", "mapping": "$tensor.0"}},
  {"name": "output_probability", "dataType": "float32", "shape": ["dynamic", "dynamic"],
   "semantic": "classification.scores",
   "transformations": [{"type": "tensor.reduce", "parameters": {"operation": "max"}, "result": "best"}],
   "workflowOutput": {"name": "ergebnis", "type": "json",
     "mapping": {"label": "$outputs.output_label.tensor.0", "score": "$best.0"}}}
]
```

Die Tests prüfen das mit echten Modellen (`local-runtime/python/tests/fixtures/sklearn`,
erzeugt mit `build_fixtures.py`): Klassifikator mit Text-Klassen und ZipMap, Regressor und
eine Pipeline mit Textspalte (`OneHotEncoder`).

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
