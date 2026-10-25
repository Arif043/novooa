# Entscheidung: ML-Inferenz nur lokal

> Modellinferenz und Import eigener Modelle laufen nur in der Runtime; Firebase betreibt nur den Modellkatalog als Verteilstelle.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Fähigkeit | Firebase | Runtime |
| --- | --- | --- |
| Modellinferenz ausführen | nein | ja |
| Eigenes Modell importieren | nein | ja |
| Kuratierte Modelle beziehen | Katalog (`modelCatalog`) | Sync oder Offline-Bundle |
| Modelle veröffentlichen (Betreiber) | ja, `models:publish` | — |

## Warum

- **Zielgruppe:** Kanzleien, Steuerberatung, Praxen, Behörden, Industrie
  haben tabellarische Scoring-Modelle auf eigenen Daten und hohen
  Dokumentendurchsatz.
- **Kosten:** Inferenz auf Kundenhardware kostet novooa nichts. Eine warme
  Cloud-Run-Instanz (2 vCPU, 4 GiB, europe-west3) kostete rund 32 USD/Monat
  im Leerlauf — mehr als die erwartete Nutzung; ohne sie wären Kaltstarts
  normal.
- **Verkauf:** Eigene Modelle sind ein Datenhoheits-Merkmal; der gepflegte
  Katalog begründet die Jahreslizenz
  ([Lokales Lizenzmodell](./lokales-lizenzmodell.md)).
- **Kein Gateway:** Die Runtime spricht ihren ML-Dienst direkt an; ein
  eigener Inferenz-Gateway entfällt.

## Umsetzungsstand

Umgesetzt: Der Cloud-Run-Inferenzdienst samt Gateway
(`model-inference-service.ts`, `Dockerfile.model-inference`,
`cloudbuild.model-inference.yaml`, Cloud-Run-Vorlage) ist entfernt. Es
bleiben die Use Cases und Ports, der ML-Dienst
(`Dockerfile.model-inference-sidecar`) und `models:publish`.

## Siehe auch

- [Auflagen an den Modellkatalog](./modellkatalog-auflagen.md)
- [Katalogmodelle cachen](./katalogmodelle-cachen.md)
