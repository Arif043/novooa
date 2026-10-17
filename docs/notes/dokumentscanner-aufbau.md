# Aufbau des Dokumentenscanners

> Eine frameworkfreie Domain mit Ports und `Result`-Rückgaben; die Web-Infrastruktur wird per bedingtem Import gewählt.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

```text
lib/features/document_scan/
├── domain/
│   ├── entities/      ScanQuad, ScannedDocument, DocumentScanFailure
│   ├── repositories/  DocumentScanner, DocumentScanSession (Ports)
│   ├── services/      ScanQuadStabilizer
│   └── usecases/      OpenDocumentScanSession
├── infrastructure/    Web-Implementierung (Kamera, JS-Brücke); sonst Platzhalter
└── presentation/      DocumentScanCubit, DocumentScanPage, Widgets
web/document_scanner/  JS-Brücke, Erkennung und Bibliotheken
```

- `DocumentScanner.open()` und `DocumentScanSession.capture()` liefern
  `Result<…, DocumentScanFailure>` (`multiple_result`), keine Exceptions.
- `document_scanner_platform.dart`: im Browser `WebDocumentScanner`, sonst ein
  Platzhalter mit `unsupported`.
- Der Cubit fragt die Erkennung alle 150 ms nacheinander ab (nie zwei
  gleichzeitig) und gibt die Kamera beim Schließen frei, auch während sie sich
  öffnet.
- `ScanQuadStabilizer` (`domain/services/`) macht die Kontur ruhig: Sie
  erscheint erst, wenn zwei Erkennungen übereinstimmen (Ecken höchstens 6 %
  auseinander); ein einzelner Ausreißer wird übergangen, ein bestätigter ist ein
  neues Blatt; Bewegungen unter 0,4 % bleiben stehen, größere folgen zur
  Hälfte; nach fünf Bildern ohne Treffer verschwindet sie.
- `ScanQuadOverlay` lässt die Kontur in 150 ms zur neuen Lage gleiten und blendet
  sie weich ein und aus.
- Registriert in beiden DI-Graphen (`service_locator.dart`,
  `standalone_dependency_configuration.dart`).
- Tests: `test/features/document_scan/` (Cubit, Stabilisierer, Overlay und
  alle UI-Zustände, 48-px-Touch-Ziel, große Schrift),
  `test/core/platform/document_scan_support_test.dart` und
  `test/web/document_quad_detector_test.mjs` (Erkennung, mit Node).

## Siehe auch

- [Dokumentenscanner im Browser](./dokumentscanner-web.md)
