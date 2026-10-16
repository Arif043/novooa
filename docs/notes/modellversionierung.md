# Modellversionierung

> Arbeitspläne pinnen `{modelId, versionId}`; ein `contractHash` zeigt, ob zwei Versionen austauschbar sind. (Geplant, noch nicht im Code.)

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

- Ein Eintrag führt mehrere Versionen; jedes Artefakt ist je Version
  unveränderlich.
- **`contractHash`** über den normalisierten Vertrag: Eingangsnamen,
  Datentypen, Shapes, Ausgangsnamen, `workflowOutput`-Namen. Gleicher Hash =
  nachweisbar austauschbar; anderer Hash = Breaking Change mit Entscheidung im
  Aufgabenstudio.

| Richtlinie je Baustein | Verhalten |
| --- | --- |
| `pinned` (Standard) | genau die gewählte Version |
| `latest-compatible` | neuere Versionen nur bei gleichem `contractHash` (neu trainiert: gleiche Spalten, neue Gewichte) |

| Zustand | Wirkung |
| --- | --- |
| `active` | regulär verwendbar |
| `deprecated` | läuft, warnt im Aufgabenstudio |
| `withdrawn` | bricht mit klarer Meldung ab (für lizenz- oder sicherheitsproblematische Modelle) |

**Reproduzierbarkeit:** Das Run-Protokoll hält `modelId`, `versionId` und den
`sha256` des Artefakts fest; ohne ihn ist ein Ergebnis später nicht
nachvollziehbar.

## Siehe auch

- [Auflagen an den Modellkatalog](./modellkatalog-auflagen.md)
- [ML-Katalogeintrag](./ml-katalogeintrag.md)
