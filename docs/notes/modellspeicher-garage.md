# Modellspeicher auf Garage

> Der globale Modellspeicher ist ein Bucket in Garage auf unserem VPS: Der Betreiber schreibt über die S3-API, ML-Dienste lesen anonym über den Website-Endpunkt.

Gehört zu: [Betrieb und Deployment](../index/betrieb-und-deployment.md) · [ML-Modelle](../index/ml-modelle.md)

| Zugriff | Endpunkt | Wer |
| --- | --- | --- |
| Schreiben, `HeadObject` | S3-API (Garage-Port 3900) | `models:publish` mit Schlüssel |
| Lesen | Website-Endpunkt (Garage-Port 3902) | ML-Dienst über `MODEL_STORE_URL`, ohne Schlüssel |

## Produktion

Garage v2.3.0 auf dem VPS, verwaltet mit Coolify (Projekt „novooa S3“).

| Zweck | Adresse |
| --- | --- |
| S3-API (`MODEL_STORE_S3_ENDPOINT`) | `https://models.arif-it.de`, Region `garage` |
| Website-Endpunkt (`NOVOOA_MODEL_STORE_URL`) | `https://web-novooa-models.arif-it.de` |
| Admin-API | `https://admin-novooa-models.arif-it.de` (Token in Coolify) |
| Bucket (`MODEL_STORE_S3_BUCKET`) | `web-novooa-models.arif-it.de` |

Der Website-Endpunkt wählt den Bucket über den Host-Namen; deshalb trägt der
Bucket als globalen Alias genau die Web-Domain.

## Einrichten

Im Terminal des Garage-Containers (Coolify → Terminal):

```bash
garage status                                   # Knoten-ID; ohne Layout zuerst:
garage layout assign -z dc1 -c 100G <knoten-id> # Kapazität nach Plattenplatz
garage layout apply --version 1
garage bucket create web-novooa-models.arif-it.de
garage key create novooa-publisher             # Schlüssel-ID und Geheimnis notieren
garage bucket allow --read --write --owner web-novooa-models.arif-it.de --key novooa-publisher
garage bucket website --allow web-novooa-models.arif-it.de
```

- Die CLI nutzt Pfad-Adressen (Standard), weil der Bucketname Punkte enthält
  und Garage dafür keine Subdomain-Adressen bedient.
- Schlüssel-ID und Geheimnis gehören nur zum Betreiber
  (`MODEL_STORE_S3_ACCESS_KEY_ID`, `MODEL_STORE_S3_SECRET_ACCESS_KEY`), nie ins Repo.

## Geprüft

2026-10-27, mit dem S3-Adapter der CLI und einer Probedatei unter `_probe/`
(danach gelöscht): Multipart-Upload mit Schlüssel, Prüfsumme aus den
Objekt-Metadaten (`x-amz-meta-sha256`) beim `HeadObject` zurück, anonymer Abruf
über den Website-Endpunkt mit identischem Inhalt.

## Warum so

- Garage kennt keine ACLs je Objekt und keinen anonymen Zugriff auf die
  S3-API; öffentlich lesbar ist nur ein Bucket im Website-Modus. Deshalb liegen
  in diesem Bucket ausschließlich Modelldateien.
- Vertrauen braucht der Lesepfad nicht: Der ML-Dienst prüft jede Datei gegen
  Größe und SHA-256 aus dem Katalog ([Modellbündel](./modellbuendel.md)).

## Offen

- Ein einzelner VPS mit `replication_factor = 1` hat keine Redundanz:
  Sicherung der Modelldateien (die meisten liegen zusätzlich im Repo oder bei
  der Quelle) festlegen.

## Siehe auch

- [Globaler Modellspeicher](./globaler-modellspeicher.md)
- [Modelle veröffentlichen](./modelle-veroeffentlichen.md)
