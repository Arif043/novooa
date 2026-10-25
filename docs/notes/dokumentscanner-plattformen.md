# Dokumentenscanner: Plattformen

> Android und iOS scannen nativ, der Browser mit eigenem Scanner; Desktop hat keinen Scanner und bietet „Dokument scannen“ nicht an.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

| Plattform | Umsetzung | Erkennung |
| --- | --- | --- |
| Android | Plugin `cunning_document_scanner` (Google ML Kit) | im Plugin, eigene Oberfläche |
| iOS | Plugin `cunning_document_scanner` (VisionKit) | im Plugin, eigene Oberfläche |
| Web | eigener Scanner in `lib/features/document_scan/` | live im Kamerabild |
| macOS, Windows, Linux | kein Scanner | „Dokument scannen“ fehlt, Aufnahme über `image_picker` |

- Entscheidung in `lib/core/platform/document_scan_support.dart`:
  `nativeDocumentScanSupportedOnThisPlatform()`,
  `webDocumentScanSupportedOnThisPlatform()` und
  `documentScanSupportedOnThisPlatform()` (ob das Bildfeld „Dokument
  scannen“ anbietet). Der Baustein legt das nicht fest; es zählt das Gerät,
  auf dem jemand antwortet.
- Bauen und Ausführen dürfen auf verschiedenen Plattformen passieren: Browser
  scannt mit seinem, Handy mit dem nativen Scanner.
- Nativ: minSdk 24 mit `CAMERA`, iOS 13.0 mit `NSCameraUsageDescription`; nur
  eine Seite (`noOfPages: 1`). Scheitert es, meldet das Bildfeld „Das Bild
  konnte nicht übernommen werden.“

## Siehe auch

- [Formulareingabe](./formulareingabe-baustein.md)
- [Dokumentenscanner im Browser](./dokumentscanner-web.md)
