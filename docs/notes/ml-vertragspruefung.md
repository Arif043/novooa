# Vertragsprüfung

> Beim Import und Cachen prüft der Python-Dienst Kette, Parameter und Setting-Bindungen jedes Modellvertrags und lehnt Fehler mit verständlicher Meldung ab.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

`PythonModelContractValidator` ruft `POST /v1/contract-validations` mit
`{contract}`. Je Ein- und Ausgang:

1. **Kette:** *„Eingang bild: audio.melSpectrogram erwartet audio, erhält
   image.“*
2. **Parameter** gegen das Schema:
   - fehlend: *„Eingang bild: image.resize: Der Parameter width fehlt.“*
   - unbekannt, mit Vorschlag: *„… Unbekannter Parameter iouTreshold —
     gemeint ist vermutlich iouThreshold.“*
   - falscher Typ/Bereich, auch verschachtelt: *„… tensor.topK: k erwartet
     eine ganze Zahl ≥ 1, erhält 0.“*
3. **Setting-Bindungen** (`"$name"`): Slider brauchen passende Grenzen (bei
   ganzen Zahlen ganzzahlige Schrittweite), Checkboxen passen nur zu
   Wahrheitswerten, Auswahlen nur, wenn jede Option gültig ist. Bindungen an
   Workflow-Werte (`$iteration.value.bounds.left`) sind erst zur Laufzeit
   bekannt und werden nicht geprüft.

Vor jeder Pipeline prüfen die Worker die Kette erneut; Parameter und
Abhängigkeiten zwischen ihnen (`min ≤ max`) prüfen die Strategien zur
Laufzeit selbst.

`GET /v1/transformation-capabilities` liefert alle Typen mit
`{accepts, produces}` und Parameterschema (`type`, `optional`, `default`,
Grenzen, Optionen, Felder).

Warum Python prüft: Der Dienst ist die verbindliche Quelle der unterstützten
Transformationen. Unbekannte Quelltypen (`file`) lehnt die Runtime schon beim
Import mit Nennung des Typs ab.

## Siehe auch

- [Wertarten und Kettenregeln](./ml-wertarten-und-ketten.md)
- [Aufbau des Python-ML-Dienstes](./python-ml-dienst-aufbau.md)
- [Eigenes Modell importieren](./eigenes-modell-importieren.md)
