# Entscheidung: ML-Inferenz nur lokal

> Modellinferenz und Import eigener Modelle sind der lokalen Variante vorbehalten; die Cloud betreibt nur den Modellkatalog als Verteilstelle.

Gehört zu: [ML-Modelle](../index/ml-modelle.md)

| Fähigkeit | Cloud | Lokal |
| --- | --- | --- |
| Modellinferenz ausführen | nein | ja |
| Eigenes Modell importieren | nein | ja |
| Kuratierte Modelle beziehen | Katalogdienst | Sync oder Offline-Bundle |
| Modelle veröffentlichen (Betreiber) | ja, `models:publish` | — |

Ein Cloud-Arbeitsplan soll `modelInference` nicht nutzen; das Aufgabenstudio
blendet ihn dort aus und verweist auf die lokale Variante.

## Warum

- **Zielgruppe:** Kanzleien, Steuerberatung, Praxen, Behörden, Industrie
  haben tabellarische Scoring-Modelle auf eigenen Daten und hohen
  Dokumentendurchsatz; Cloud-Kunden selten eigene Modelle.
- **Kosten:** Inferenz auf Kundenhardware kostet novooa nichts. Eine warme
  Cloud-Run-Instanz (2 vCPU, 4 GiB, europe-west3) kostete rund 32 USD/Monat
  im Leerlauf — mehr als die erwartete Nutzung; ohne sie wären Kaltstarts
  normal.
- **Verkauf:** Eigene Modelle sind ein Datenhoheits-Merkmal; der gepflegte
  Katalog begründet die Jahreslizenz
  ([Lokales Lizenzmodell](./lokales-lizenzmodell.md)).
- **Geringer Schnitt:** Gateway und Sidecar bleiben; entfallen würde nur der
  Cloud-Run-Zustellweg.

## Umsetzungsstand

Noch nicht umgesetzt: Der [Cloud-Inferenzdienst](./cloud-inferenzdienst.md)
existiert weiter (`infrastructure/cloud_run/`). Laut Entscheidung entfallen
`CloudRunModelInference`, `cloudbuild.model-inference.yaml`, die
Cloud-Run-Vorlage, `MODEL_INFERENCE_SERVICE_URL` und die
`roles/run.invoker`-Bindung. Bleiben: `docker-compose.model-inference.yaml`,
`functions/Dockerfile.model-inference`, alle Use Cases und Ports,
`models:publish`. Der Port bleibt, damit ein Cloud-Adapter wieder einhängbar
ist.

## Siehe auch

- [Auflagen an den Modellkatalog](./modellkatalog-auflagen.md)
- [Katalogmodelle cachen](./katalogmodelle-cachen.md)
