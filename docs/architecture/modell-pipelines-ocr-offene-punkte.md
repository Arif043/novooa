# Modell-Pipelines und OCR: Offene Punkte

Der aktuelle Stand ist eine technische Grundlage, aber noch keine vollständige
OCR-Pipeline.

## Für Jedes Element

- Sichtbare Validierung für Pointer, leere Unterpläne, pausenfähige Bausteine
  und verschachtelte Schleifen fehlt.
- Der Unterplan ist im Builder eingebettet; eine eigenständige Canvas-Navigation
  ist noch keine eigene Ansicht.
- Zusätzliche Runner-End-to-End-Tests für echte Unterpläne fehlen.

Der Builder kann den eingebetteten Graphen anlegen, konfigurieren, verschieben
und löschen. Pro Iteration stehen `{{iteration.value}}` und
`{{iteration.index}}` zur Verfügung; die Ausgaben aller Unterplan-Bausteine
werden unter ihren Referenznamen aggregiert.

## Modellverträge

- JSON-Pointer-Bindungen für Modelleingänge fehlen, etwa `/source` oder
  `/polygon` aus einem Vorgängerwert.
- Dynamische Transformationsparameter sind als deklarative
  Ausführungskontext-Referenzen verfügbar, etwa `$iteration.value.bounds`.
- Eingabe- und Ausgabetransformationen laufen in Python; der Workflow erhält
  bereits fachliches JSON statt Base64-Tensoren.
- Der verfügbare Katalog umfasst CTC-Dekodierung, Maskenregionen,
  Koordinatenrückrechnung und seitenverhältnistreues Resize mit Padding. Weitere
  allgemeine Strategien ergänzen wir über die Registry, nicht modellspezifisch.
- Modellressourcen wie Zeichenlisten, Tokenizer oder Labels fehlen.
- Ressourcen-Publishing und -Validierung in der Betreiber-CLI fehlen.

## OCR-Nachweis

- PaddleOCR-Detektor- und Erkenner-ONNX-Dateien fehlen.
- Manifest-Dateien und eine Zeichenlistenressource fehlen.
- Eine datenschutzgeprüfte Beleg-Fixture fehlt.
- Detektor- und Erkenner-Manifeste einschließlich Modell-Stride,
  Regionsrückprojektion, Bildzuschnitt und CTC-Zeichenliste fehlen.
- Lokale sowie Cloud-Run-End-to-End-Tests fehlen.

## Architekturentscheidung

`fromOutput` wurde entfernt. Kanten bleiben reine Abhängigkeiten; künftig
wählen Nachfolger die benötigten Werte über ihre eigenen JSON-Pointer-Bindungen.

Der sichtbare Hauptgraph ist daher noch kein vollständiger OCR-Ablauf: Der
Erkenner muss im Unterplan des `Für jedes Element`-Bausteins liegen, und die
Modellverträge müssen die konkrete Modellvor- und -nachverarbeitung beschreiben.
