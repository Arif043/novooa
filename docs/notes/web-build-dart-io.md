# `dart:io` im Web-Build ist kein Blocker

> `image_picker_media_input_picker.dart` importiert `dart:io`, bricht den Web-Build aber nicht, weil der einzige `File()`-Aufruf im Web nie erreicht wird.

Gehört zu: [Betriebsvarianten](../index/betriebsvarianten.md)

- `flutter build web` läuft durch (verifiziert).
- Der `File()`-Aufruf liegt in `_pickWithDocumentScanner()`, erreichbar nur
  über `documentScanSupportedOnThisPlatform()` = `!kIsWeb && (android || iOS)`.

Festgehalten, damit die Stelle nicht erneut als Blocker gemeldet wird.

## Siehe auch

- [Dokumentenscanner: Plattformen](./dokumentscanner-plattformen.md)
