# Modell-Pipelines und `forEach`

`forEach` ist ein regulärer Workflow-Baustein. Seine Konfiguration enthält
`itemsPointer` und einen eingebetteten Graphen. Der Executor löst den Pointer
gegen den JSON-`value` des direkten Vorgängers auf und ruft den bestehenden
`SubgraphRunner` für jedes Element auf.

```text
JSON value -> RFC-6901 pointer -> serial subgraph runs -> JSON array value
```

Der Runner übergibt den Iterationswert als synthetischen `value`-Vorgänger nur
an Wurzelknoten des Unterplans. Normale Unterplan-Kanten behalten Vorrang.
Damit bleiben Iterationen voneinander isoliert und die bestehende
Topologieausführung unverändert.

Kanten enthalten keine Datenauswahl. Nachfolger binden benötigte Werte über
ihren eigenen Vertrag, damit der Datenfluss an einer Stelle konfiguriert bleibt.

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
