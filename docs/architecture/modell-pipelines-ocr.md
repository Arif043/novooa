# Modell-Pipelines und `forEach`

`forEach` ist ein regulärer Workflow-Baustein. Seine Konfiguration enthält
`itemsPointer` und einen eingebetteten Graphen. Der Executor löst den Pointer
gegen den JSON-`value` des direkten Vorgängers auf und ruft denselben
Graph-Runner für jedes Element auf.

```text
JSON value -> RFC-6901 pointer -> serielle Graph-Ausführungen -> strukturierte JSON-Liste
```

Jede Iteration erhält zusätzlich den expliziten Ausführungskontext
`iteration` mit `index` und `value`. Bausteine des eingebetteten Graphen lesen ihn über
ihre normalen Workflow-Mappings, etwa `{{iteration.value.bounds}}` oder
`{{iteration.index}}`. Der synthetische `value`-Vorgänger bleibt für
Bausteine ohne eigene Zuordnung erhalten; normale Kanten des eingebetteten Graphen haben
weiterhin Vorrang. Damit bleiben Iterationen voneinander isoliert und die
bestehende Topologieausführung unverändert. Der eingebettete Graph erhält außerdem den schreibgeschützten Kontext des äußeren Graphen: `{{global.eingabe.value}}`, `{{global.input.feld}}` und `{{global.variables.name}}`. Äußere Knotenausgaben dürfen auch kurz als `{{eingabe.value}}` referenziert werden, sofern der eingebettete Graph keinen gleichnamigen Baustein enthält.

Kanten enthalten keine Datenauswahl. Nachfolger binden benötigte Werte über
ihren eigenen Vertrag, damit der Datenfluss an einer Stelle konfiguriert bleibt.

Die Ausgabe des Bausteins ist eine Liste. Jedes Listenelement enthält die
Ausgaben der im eingebetteten Graphen ausgeführten Bausteine unter ihrem Referenznamen,
beispielsweise `{{regionen.value.0.erkenner.text}}`. Damit gehen bei
eingebetteten Graphen mit mehreren Ausgaben keine Werte verloren.

## Inferenzdienst

Der private Cloud-Run-Inferenzdienst skaliert als vollständige Instanzpaare:

```text
Cloud-Run-Instanz = Node-Gateway + Python-ONNX-Sidecar
```

Der Node-Container ist der HTTP-Eingang und prüft das Manifest, Teamzugriff
und Artefaktintegrität. Der Python-Sidecar führt ONNX-Inference in einem
langlebigen Prozess aus. Die Vorverarbeitung bleibt in der ersten Stufe beim
vorhandenen Worker. Beide Container kommunizieren innerhalb derselben Instanz
über `127.0.0.1`.

Artefakt- und Session-Caches sind lokal und LRU-begrenzt. Cloud Run kann keine
Instanz nach vorhandenem Modellcache auswählen; ein Cache-Hit ist deshalb eine
Optimierung, keine Routing-Garantie.
