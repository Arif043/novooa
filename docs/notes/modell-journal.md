# Modell-Journal

> Jedes Modell, das in den Katalog aufgenommen wird, hat einen Journal-Eintrag neben seinem Manifest: Herkunft, Lizenz, Dokumentation, Vertrag, Prüfungen und Verlauf.

Gehört zu: [Modellkatalog](../index/modellkatalog.md) · [ML-Modelle](../index/ml-modelle.md)

## Ablage

Jedes Systemmodell hat einen Ordner `models/<modell>/` mit Manifest
`model.json`, Journal-Eintrag `JOURNAL.md` und, wo eingecheckt, den
Modelldateien.

Das Manifest wird nicht ins Journal kopiert; der Eintrag verweist darauf und
hält fest, welche Version veröffentlicht wurde. Jede Zeile der Übersicht im
[Modellkatalog](../index/modellkatalog.md) verlinkt einen Eintrag.

## Ablauf beim Import

1. **Auswahl und Lizenz:** Lizenz von Gewichten, Code und Trainingsdaten
   prüfen; nur Lizenzen, die kommerzielle Nutzung erlauben. Eintrag mit Status
   `in Prüfung` anlegen und in der Übersicht ergänzen.
2. **Dateien:** Artefakte aus der Quelle holen, Quelle (URL, Datei, Commit
   oder Release) und SHA-256 jeder Datei festhalten.
3. **Manifest:** `task`, Sprachen und Tags aus dem
   [Tag-Vokabular](./modell-tag-vokabular.md) wählen — fehlende Tags erst in
   `models/tags.json` ergänzen. Vor- und Nachverarbeitung nach der
   Referenzimplementierung mit [Transformationen](../index/transformationen.md)
   beschreiben; Abweichungen im Eintrag nennen.
4. **Prüfung:** Trockenlauf mit `models:install-local … --dry-run`
   (Vertrag, ONNX, Tags) und fachlicher Referenztest: Referenzeingabe,
   erwartete Ausgabe der Originalimplementierung, unsere Ausgabe — als
   dauerhafter Test nach dem Muster in den
   [Regeln für Transformationen](./regeln-fuer-transformationen.md). Ergebnis
   und Datum eintragen, Status `geprüft`.
5. **Veröffentlichen:** neue Tags mit `models:tags:publish`, dann
   [`models:publish`](./modelle-veroeffentlichen.md); Befehl, Datum und
   Version im Verlauf, Status `veröffentlicht`.
6. **Änderungen:** neue Version, Rückzug (`zurückgezogen`) oder neue
   Lizenzlage immer als datierte Zeile im Verlauf.

## Vorlage

```markdown
# <Titel> (`<modell-id>`)

> Journal des Katalogmodells; Manifest: [`model.json`](./model.json).

**Status:** in Prüfung | geprüft | veröffentlicht | zurückgezogen

## Steckbrief
ID `<modell-id>`, Version `<versionId>`, Aufgabe, Sprachen, Tags.

## Herkunft
Quelle, Datei, Commit/Release; SHA-256 je Datei; wer, wann.

## Lizenz
Gewichte, Code, Trainingsdaten, Namensnennung; Bewertung offen oder geklärt.

## Dokumentation
Paper, Model Card, Referenzimplementierung der Vor- und Nachverarbeitung.

## Vertrag
Ein- und Ausgänge, verwendete Transformationen, Abweichungen von der Referenz.

## Prüfung
Vertrags- und ONNX-Prüfung, Trockenlauf, fachlicher Referenztest mit Datum.

## Grenzen
Bekannte Schwächen, Eingabegrößen, Laufzeit.

## Verlauf
- JJJJ-MM-TT — Ereignis
```

`shipped-model-manifests.test.ts` prüft: jedes mitgelieferte Manifest hat
einen Eintrag mit allen Abschnitten, der Eintrag nennt ID und Version, die
SHA-256 einer eingecheckten `model.onnx` stimmt, und die Übersicht verlinkt
ihn.

## Siehe auch

- [Modelle veröffentlichen](./modelle-veroeffentlichen.md)
- [Auflagen an den Modellkatalog](./modellkatalog-auflagen.md)
- [Regeln für Transformationen](./regeln-fuer-transformationen.md)
