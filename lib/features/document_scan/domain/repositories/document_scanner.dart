import 'package:multiple_result/multiple_result.dart';

import '../entities/document_scan_failure.dart';
import '../entities/scan_quad.dart';
import '../entities/scanned_document.dart';

abstract interface class DocumentScanner {
  /// Startet die Kamera und die Dokumenterkennung.
  Future<Result<DocumentScanSession, DocumentScanFailure>> open();
}

/// Eine laufende Aufnahme: Kamerabild, Erkennung und Aufnahme.
abstract interface class DocumentScanSession {
  /// Kennung der Vorschau; die Oberfläche bindet damit das Kamerabild ein.
  String get previewId;

  /// Breite geteilt durch Höhe des Kamerabilds, damit die erkannte Kontur
  /// genau über der Vorschau liegt.
  double get aspectRatio;

  /// Das Dokument im aktuellen Kamerabild, oder `null`, wenn keines erkannt ist.
  Future<ScanQuad?> detect();

  /// Nimmt das aktuelle Bild auf. Mit [quad] wird das Dokument begradigt, ohne
  /// [quad] kommt das ganze Bild zurück.
  Future<Result<ScannedDocument, DocumentScanFailure>> capture(ScanQuad? quad);

  Future<void> close();
}
