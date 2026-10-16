# ML-Scope und Modellkatalog

## Entscheidung

Das Feature `machine_learning` — ONNX-Inferenz und der Import eigener Modelle —
bleibt der **lokalen Variante** vorbehalten. Die Cloud führt keine Modelle aus.

novooa betreibt stattdessen einen **Modellkatalog als Cloud-Dienst**: eine
Verteilstelle, aus der lokale Runtimes kuratierte Modelle beziehen. Ausgeführt
wird ausschließlich auf Kundenhardware.

## Begründung

**Zielgruppenpassung.** Die lokale Variante adressiert Kanzleien,
Steuerberatung, Praxen, Behörden und Industrie. Das ist genau das Segment mit
tabellarischen Scoring-Modellen auf eigenen Daten und mit hohem
Dokumentendurchsatz. Ein Cloud-Kunde im Starter- oder Pro-Plan hat selten ein
eigenes trainiertes Modell.

**Kosten.** Inferenz auf Kundenhardware verursacht novooa keine Rechenkosten.
Die Cloud-Alternative hätte eine warme Cloud-Run-Instanz erfordert (2 vCPU,
4 GiB, europe-west3: rund 32 USD/Monat im Leerlauf) — mehr als die gesamte
zu erwartende Nutzung. Ohne warme Instanz wären Kaltstarts der Normalfall.

**Verkaufsargument.** Eigene Modelle einbinden ist ein Datenhoheits-Merkmal und
gehört damit zur Abgrenzung, die `kosten-und-abo-preise.md` beschreibt. Der
laufend gepflegte Katalog begründet zusätzlich die Jahreslizenz gegenüber einem
Einmalkauf.

**Geringer Schnitt.** Node-Gateway und Python-Sidecar sind der lokale Stack.
Entfallen würden nur der Cloud-Run-Zustellweg und seine Konfiguration, kein
Architekturbestandteil.

## Scope-Verteilung

| Fähigkeit | Cloud | Lokal |
| --- | --- | --- |
| Modellinferenz ausführen | nein | ja |
| Eigenes Modell importieren | nein | ja |
| Kuratierte Modelle beziehen | Katalogdienst | Sync oder Offline-Bundle |
| Modelle veröffentlichen (Betreiber) | ja, `models:publish` | — |

Ein Cloud-Arbeitsplan kann den Baustein `modelInference` nicht verwenden. Der
Task Builder blendet ihn in der Cloud-Variante aus und verweist auf die lokale
Variante.

## Modellkatalog als Cloud-Dienst

Firestore `modelCatalog` bleibt der Master. Die Betreiber-CLI `models:publish`
bleibt unverändert; lokale Runtimes lesen die Metadaten nach ihrer Firebase-
Anmeldung direkt aus Firestore. Die Artefakte werden nicht über novooa
proxied, sondern vom ML-Dienst jedes Servers direkt aus dem globalen
Modellspeicher (Hetzner Object Storage, öffentlich lesbar) geladen.

```text
GET /v1/ml-models/catalog
POST /v1/ml-models/catalog/:modelId/install
```

Der Endpunkt liefert Katalogeinträge samt Manifest als kleine JSON-Nutzlast.
Das Cachen lässt anschließend den ML-Dienst die Dateien unter
`model-artifacts/<artifact-id>/versions/<version-id>/` vorladen; die Runtime speichert
nur den Katalogeintrag. Firestore liefert nur Metadaten; ein unauthentifizierter
Katalogzugriff ist nicht vorgesehen. Details:
[Modellbündel](../notes/modellbuendel.md).

### Auflagen

Diese vier Punkte sind Bestandteil der Entscheidung, nicht optionale
Verbesserungen.

**1. Integrität.** Ein Modellkanal in ein Kundennetz ist ein Code-Lieferkanal.
Der Katalog enthält deshalb Größe und SHA-256-Prüfsumme jeder Datei; Versionen
im Modellspeicher sind unveränderlich. Der ML-Dienst prüft Größe und Prüfsumme,
bevor ein Bündel sichtbar wird.

**2. Optionalität.** Offline-Aktivierung ist ein Enterprise-Merkmal; solche
Installationen haben keinen Internetzugang. Der Katalog braucht daher einen
manuellen Weg: ein signiertes Bundle aus Manifest und Artefakt, das per
Datenträger eingespielt wird. Eine Runtime ohne Katalogverbindung bleibt
vollständig funktionsfähig.

**3. Keine Telemetrie.** Der Katalogabruf übermittelt nicht, welche Modelle wie
oft ausgeführt werden. Ein Listenabruf und ein Download, mehr nicht. Nachträglich
ist diese Eigenschaft nicht mehr glaubhaft herzustellen.

**4. Kein Auto-Update.** Der Sync holt Metadaten. Welche Version installiert
wird, entscheidet die Administration der Installation — auch dann, wenn der
Vertrag unverändert bleibt.

## Versionierung

Der Katalogeintrag führt mehrere Versionen; das Artefakt bleibt je Version
unveränderlich (`ifGenerationMatch: 0`).

**Arbeitspläne pinnen `{modelId, versionId}`.** Ein automatisches Upgrade findet
nicht statt.

**`contractHash`** ist ein Hash über den normalisierten Vertrag: Eingangsnamen,
Datentypen, Shapes, Ausgangsnamen und `workflowOutput`-Namen. Zwei Versionen mit
gleichem `contractHash` sind nachweisbar austauschbar; ein abweichender Hash ist
ein Breaking Change und erfordert eine Entscheidung im Task Builder.

**Versionsrichtlinie je Baustein:**

| Richtlinie | Verhalten |
| --- | --- |
| `pinned` (Default) | Verwendet genau die gewählte Version. |
| `latest-compatible` | Übernimmt neuere Versionen nur bei gleichem `contractHash`. |

`latest-compatible` bedient den Fall des regelmäßig neu trainierten Modells:
gleiche Spalten, neue Gewichte.

**Versionszustände:**

| Zustand | Wirkung |
| --- | --- |
| `active` | Regulär verwendbar. |
| `deprecated` | Läuft weiter, warnt im Task Builder. |
| `withdrawn` | Bricht mit klarer Meldung ab. |

`withdrawn` ist erforderlich, um ein Modell zurückziehen zu können, das sich als
lizenz- oder sicherheitsproblematisch erweist.

**Reproduzierbarkeit.** Das Run-Protokoll hält `modelId`, `versionId` und den
`sha256` des verwendeten Artefakts fest. Der Hash wird ohnehin berechnet; ohne
ihn ist ein Ergebnis später nicht nachvollziehbar.

## Katalogwachstum

Ab etwa dreißig Einträgen trägt die flache Liste mit `tags` nicht mehr. Der
Katalogeintrag erhält eine `taskType`-Facette (`classification.image`,
`ocr.text`, `regression.tabular`, `classification.tabular`), über die Suche und
Filter laufen.

Der Session-Cache wird **nach Bytes** begrenzt, nicht nach Einträgen
(`MODEL_SESSION_CACHE_BYTES`): Zweihundert tabellarische Modelle belegen zusammen
etwa ein Megabyte, drei OCR-Modelle über hundert.

## Modellklassen und ONNX-Domänen

novooa legt keine Operator-Domäne fest. Die Domäne steht in der Modelldatei; die
ONNX-Runtime lädt die passenden Kernel. Der Domänenschicht ist die Methode
unbekannt.

| Methode | Domäne | Stand |
| --- | --- | --- |
| CNN, Bildklassifikation, OCR | `ai.onnx` | unterstützt |
| MLP, klassisches neuronales Netz | `ai.onnx` | unterstützt |
| SVM (Klassifikation, Regression) | `ai.onnx.ml` | Lücken siehe unten |
| Random Forest, Gradient Boosting | `ai.onnx.ml` | Lücken siehe unten |
| Lineare, logistische Regression | `ai.onnx.ml` | Lücken siehe unten |
| XGBoost, LightGBM (`onnxmltools`) | `ai.onnx.ml` | Lücken siehe unten |
| Transformer, Text-Embedding | `ai.onnx` | Tokenizer fehlt |

Die vorhandenen Systemmodelle verwenden ausschließlich `ai.onnx`. Der
PP-OCRv3-Detektor deklariert `opset_import [("", 14)]` mit dreizehn
Operatortypen (`Conv`, `ConvTranspose`, `BatchNormalization`, `Resize`,
`HardSwish` und weitere); `ai.onnx.ml` kommt darin nicht vor.

### Drei Lücken für klassische ML-Modelle

Diese Punkte liegen in der Domäne und im Python-Sidecar und betreffen beide
Varianten.

1. **`string` als Tensor-Datentyp.** `ModelTensorDataType` deckt `float32`,
   `float64`, `int64`, `int32`, `int16`, `int8`, `uint8` und `bool` ab.
   scikit-learn-Klassifikatoren liefern Labels häufig als `tensor(string)`.
2. **Eingabestrategie `tabular.features`.** Die Quellarten `number`, `boolean`
   und `json` werden bereits gebunden und validiert; die technische Umwandlung in
   einen `[1, N]`-Tensor mit fester Spaltenreihenfolge fehlt.

   ```ts
   {type: "tabular.features", parameters: {
     columns: ["alter", "umsatz", "tage_seit_kauf"],
     dataType: "float64",
   }}
   ```

3. **ZipMap-Prüfung beim Import.** `skl2onnx` hängt Klassifikatoren
   standardmäßig einen `ZipMap`-Knoten an, dessen Ausgang `seq(map(int64,
   float))` ist. Das verletzt die Tensor-Grenze der Runtime. Der Import lehnt
   solche Modelle mit dem Hinweis auf `zipmap=False` ab.

Mit diesen drei Ergänzungen ist die klassische ML-Familie vollständig abgedeckt,
ohne Änderung an Vertrag, Katalog oder Ausführungspfad.

### Import-Allowlist

Für importierte Modelle prüft die Runtime die verwendeten Operatoren. Ein
`ai.onnx.ml`-Modell importiert praktisch immer auch die Default-Domäne, eine
Prüfung allein auf die Domäne genügt daher nicht.

```python
model = onnx.load(path)
domains = {o.domain for o in model.opset_import}
ops = {(n.domain, n.op_type) for n in model.graph.node}
```

- `ai.onnx.ml` vollständig erlaubt
- aus der Default-Domäne eine begrenzte Liste: `Cast`, `Concat`, `Reshape`,
  `Identity`, `Transpose`, `Gather`, elementweise Arithmetik
- alles Übrige und jede fremde Domäne abgelehnt

Für Deep-Learning-Modelle gilt die Allowlist nicht; diese werden kuratiert
veröffentlicht und sind damit geprüft.

## Was aus der Cloud-Inferenz wird

**Entfällt:**

- `CloudRunModelInference` und `infrastructure/cloud_run/`
- `cloudbuild.model-inference.yaml`
- `functions/cloudrun/model-inference-service.yaml.template`
- der Functions-Parameter `MODEL_INFERENCE_SERVICE_URL`
- die `roles/run.invoker`-Bindung der Task-Worker-Function

**Bleibt:**

- `docker-compose.model-inference.yaml` — das ist der lokale Stack
- `functions/Dockerfile.model-inference`
- alle Domain-Use-Cases und Ports
- `models:publish` als Betreiberwerkzeug

Der Port `ModelInference` bleibt bestehen. Ein Cloud-Adapter wäre jederzeit
wieder einzuhängen, falls die Entscheidung revidiert wird.

## Offene Punkte

- Der Sprung von 39 EUR/Monat auf 1.990 EUR/Jahr ist groß für Cloud-Kundschaft,
  die ausschließlich OCR benötigt. Die Häufigkeit dieser Anfrage sollte vor einer
  endgültigen Festlegung beobachtet werden.
- Die Tokenisierung für Textmodelle ist ungelöst. Möglich sind
  `onnxruntime-extensions`, ein mitgeliefertes Vokabular mit eigener Strategie
  oder die Beschränkung auf vortokenisierte Eingaben.
- Das Format des Offline-Bundles ist noch nicht festgelegt.
- Ob der Katalogdienst als Function oder als Teil des bestehenden Relays läuft,
  ist offen.

## Verwandt

- [ML-Modelle](../index/ml-modelle.md)
- [Lokale Runtime](../index/lokale-runtime.md)
- [Kosten- und Preismodell](../kosten-und-abo-preise.md)
- [Aufgabe-Executoren](../features/aufgabe-executoren.md)
