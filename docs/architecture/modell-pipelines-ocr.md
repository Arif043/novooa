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
