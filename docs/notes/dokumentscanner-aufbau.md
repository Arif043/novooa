# Aufbau des Dokumentenscanners

> Eine frameworkfreie Domain mit Ports und `Result`-Rückgaben; die Web-Infrastruktur wird per bedingtem Import gewählt.

Gehört zu: [Dokumentenscanner](../index/dokumentscanner.md)

```text
lib/features/document_scan/
├── domain/
│   ├── entities/      ScanQuad, ScannedDocument, DocumentScanFailure
│   ├── repositories/  DocumentScanner, DocumentScanSession (Ports)
│   └── usecases/      OpenDocumentScanSession
├── infrastructure/    Web-Implementierung (Kamera, JS-Brücke); sonst Platzhalter
└── presentation/      DocumentScanCubit, DocumentScanPage, Widgets
web/document_scanner/  JS-Brücke und Bibliotheken
```

- `DocumentScanner.open()` und `DocumentScanSession.capture()` liefern
  `Result<…, DocumentScanFailure>` (`multiple_result`), keine Exceptions.
- `document_scanner_platform.dart`: im Browser `WebDocumentScanner`, sonst ein
  Platzhalter mit `unsupported`.
- Der Cubit fragt die Erkennung nacheinander ab (nie zwei gleichzeitig), lässt
  die Kontur bei kurzen Aussetzern drei Bilder stehen (kein Flackern) und gibt
  die Kamera beim Schließen frei, auch während sie sich öffnet.
- Registriert in beiden DI-Graphen (`service_locator.dart`,
  `standalone_dependency_configuration.dart`).
- Tests: `test/features/document_scan/` (Cubit und alle UI-Zustände,
  48-px-Touch-Ziel, große Schrift) und
  `test/core/platform/document_scan_support_test.dart`.

## Siehe auch

- [Dokumentenscanner im Browser](./dokumentscanner-web.md)
