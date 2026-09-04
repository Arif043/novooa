# Modell-Pipelines und OCR: Offene Punkte

Der aktuelle Stand ist eine technische Grundlage, aber noch keine vollständige
OCR-Pipeline.

## Für Jedes Element

- Ein Unterplan-Editor in der Oberfläche fehlt: eigene Canvas-Ansicht,
  Aktion zum Bearbeiten und Zurück-Navigation.
- Cubit-Mutationen zum Hinzufügen, Verschieben, Ändern und Löschen von
  Bausteinen im Unterplan fehlen.
- Sichtbare Validierung für Pointer, leere Unterpläne, pausenfähige Bausteine
  und verschachtelte Schleifen fehlt.
- Runner-Tests für Reihenfolge, isolierte Iterationswerte, Aggregation und
  Fail-fast fehlen.

Der Backend-Executor und die Persistenz für `ForEachNodeConfig.graph` sind
vorhanden. In der Oberfläche lässt sich dieser Graph jedoch noch nicht anlegen.

## Modellverträge

- JSON-Pointer-Bindungen für Modelleingänge fehlen, etwa `/source` oder
  `/polygon` aus einem Vorgängerwert.
- Dynamische Transformationsparameter per JSON-Pointer fehlen.
- Ausgangstransformationen sind vertraglich modelliert, werden aber von der
  Runtime noch abgewiesen.
- `modelInference` liefert weiterhin rohe Base64-Tensoren statt fachlichem
  JSON wie `{text, confidence}`.
- Ein vollständiger Transformationskatalog für Geometrie, CTC, Konfidenz,
  Labels und JSON-Projektionen fehlt.
- Modellressourcen wie Zeichenlisten, Tokenizer oder Labels fehlen.
- Ressourcen-Publishing und -Validierung in der Betreiber-CLI fehlen.

## OCR-Nachweis

- PaddleOCR-Detektor- und Erkenner-ONNX-Dateien fehlen.
- Manifest-Dateien und eine Zeichenlistenressource fehlen.
- Eine datenschutzgeprüfte Beleg-Fixture fehlt.
- Detektor- und Erkenner-Verträge einschließlich Bildzuschnitt, Entzerrung und
  CTC-Dekodierung fehlen.
- Lokale sowie Cloud-Run-End-to-End-Tests fehlen.

## Architekturentscheidung

`fromOutput` wurde entfernt. Kanten bleiben reine Abhängigkeiten; künftig
wählen Nachfolger die benötigten Werte über ihre eigenen JSON-Pointer-Bindungen.

Der sichtbare Hauptgraph ist daher noch kein vollständiger OCR-Ablauf: Der
Erkenner muss im Unterplan des `Für jedes Element`-Bausteins liegen, und die
Modellverträge müssen vorher fachliches JSON statt Tensor-Base64 erzeugen.
