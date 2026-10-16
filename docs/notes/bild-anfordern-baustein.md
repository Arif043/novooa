# Bild anfordern (`mediaInput`)

> Der Baustein pausiert den Run, bis jemand ein Bild aus Galerie oder Kamera liefert; optional als Dokumentenscan.

Gehört zu: [Aufgabe](../index/aufgabe.md)

- Quelle (Galerie oder Kamera) wählt der Nutzer während der Ausführung.
- Der Client speichert das Bild im team-scoped Dateispeicher und übergibt nur
  die `fileId`.
- Beim Fortsetzen lädt das Backend die Metadaten selbst, akzeptiert nur
  `image/*` und liefert `media` mit `fileId`, `versionId`, `displayName`,
  `contentType`, `sizeBytes`.
- **`documentScanEnabled`** („Als Dokument scannen“, Standard aus): Mit Kamera
  scannt der Client mit Randerkennung und Perspektivkorrektur (Android/iOS
  nativ, Web mit eigener Scanner-Seite). Ergebnis ist ein JPEG wie jedes
  andere Bild; das Backend reicht die Option nur durch.

## Siehe auch

- [Dokumentenscanner](../index/dokumentscanner.md)
- [Freigaben und Pausen](./freigaben-und-pausen.md)
