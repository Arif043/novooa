# ML-Modelle

> novooa verwaltet einen plattformunabhängigen Katalog klassischer ML-Modelle (ONNX) mit deklarativen Verträgen für Ein- und Ausgaben; ausgeführt wird im Python-ML-Dienst, in der Cloud wie in Standalone.

## Entscheidungen

- [Entscheidung: ML-Inferenz nur lokal](../notes/ml-nur-lokal-entscheidung.md)
- [Auflagen an den Modellkatalog](../notes/modellkatalog-auflagen.md)
- [Modellversionierung](../notes/modellversionierung.md) (geplant)
- [ONNX-Domänen und Modellklassen](../notes/onnx-domaenen-und-modellklassen.md)

## Katalog

- [ML-Katalogeintrag](../notes/ml-katalogeintrag.md)
- [Globaler Modellspeicher](../notes/globaler-modellspeicher.md)
- [Modellaufgaben, Sprachen und Tags](../notes/modellaufgaben-und-sprachen.md)
- [Mehrsprachige Manifeste](../notes/mehrsprachige-manifeste.md)
- [Modellsuche](../notes/modellsuche.md)
- [Persistenz des Modellkatalogs](../notes/modellkatalog-persistenz.md)
- [Modellordner und Manifestdatei](../notes/modellordner-und-manifest.md)

## Modellvertrag

- [Typebenen eines Modellvertrags](../notes/modell-typebenen.md)
- [Eingangsbindungen](../notes/modell-eingangsbindungen.md)
- [Modell-Settings](../notes/modell-settings.md)
- [Workflow-Output-Mapping](../notes/workflow-output-mapping.md)
- [Modelleingaben im Baustein](../notes/modelleingaben-im-baustein.md)

## Transformationen

- [Deklarative Transformationen](../notes/transformationen-deklarativ.md)
- [Transformationskatalog](../notes/transformationskatalog.md)
- [Wertarten und Kettenregeln](../notes/ml-wertarten-und-ketten.md)
- [Vertragsprüfung](../notes/ml-vertragspruefung.md)
- [Modellquellen im Worker](../notes/modellquellen-im-worker.md)
- [Aufbau des Python-ML-Dienstes](../notes/python-ml-dienst-aufbau.md)
- [Bildgeometrie und Originalkoordinaten](../notes/bildgeometrie-originalkoordinaten.md)

## Anwendungsmuster

- [Objekterkennung und Segmentierung](../notes/objekterkennung-und-segmentierung.md)
- [Klassisches ML über ONNX](../notes/klassisches-ml-onnx.md)
- [OCR-Pipeline](../notes/ocr-pipeline.md)
- [Baustein „Für jedes Element“](../notes/foreach-baustein.md)
- [Piper-Systemmodelle](../notes/piper-systemmodelle.md)

## Inferenz

- [Inferenz-Use-Cases](../notes/inferenz-use-cases.md)
- [ONNX-Inferenz über den ML-Dienst](../notes/onnx-inferenz-ml-dienst.md)
- [Schnittstelle des ML-Dienstes](../notes/ml-dienst-schnittstelle.md)
- [Modellbündel](../notes/modellbuendel.md)
- [ML-Mandanten](../notes/ml-mandanten.md)
- [Ressourcen und Warteschlange des ML-Dienstes](../notes/ml-ressourcen-und-warteschlange.md)
- [ONNX-Größengrenzen](../notes/onnx-groessengrenzen.md)

## Standalone-Verwaltung

- [Katalogmodelle cachen](../notes/katalogmodelle-cachen.md)
- [Machine-Learning-Einstellungen](../notes/ml-einstellungen.md)
- [Eigenes Modell importieren](../notes/eigenes-modell-importieren.md)

## Cloud und Betrieb

- [Cloud-Inferenzdienst](../notes/cloud-inferenzdienst.md)
- [Caches im Cloud-Run-Dienst](../notes/cloud-run-ml-caches.md)
- [Lokaler Inferenz-Stack](../notes/lokaler-inferenz-stack.md)
- [Modelle veröffentlichen](../notes/modelle-veroeffentlichen.md)

## Offene Punkte

- Weitere Eingabe- und Ausgangstransformationen als Strategien ergänzen.
- Die Cloud-Vertragsprüfung (`model-contract-capabilities.ts`) kennt die
  neueren Transformationstypen noch nicht.
- Labels von Settings sind noch nicht übersetzbar.
- Entscheidung „nur lokal“ umsetzen (Cloud-Run-Zustellweg entfernen,
  `modelInference` in der Cloud ausblenden).
- Format des Offline-Bundles; Katalogdienst als Function oder im Relay.
- Tokenisierung für Textmodelle.
- OCR-Nachweis: kuratierte PaddleOCR-Detektor- und Erkenner-Modelle,
  Manifeste mit Zeichenliste, datenschutzgeprüfte Beleg-Fixture, lokale und
  Cloud-End-to-End-Tests.
- Preisfrage: Sprung von 39 EUR/Monat auf 1.990 EUR/Jahr für Cloud-Kundschaft,
  die nur OCR braucht, beobachten.

## Verwandt

- [Sprachausgabe](../features/sprachausgabe.md)
- [Aufgabe](../index/aufgabe.md)
- [Lokale Runtime](./lokale-runtime.md)
