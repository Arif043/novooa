import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/document_scan/domain/entities/document_scan_failure.dart';
import 'package:syscat2/features/document_scan/domain/entities/scan_quad.dart';
import 'package:syscat2/features/document_scan/domain/entities/scanned_document.dart';
import 'package:syscat2/features/document_scan/domain/repositories/document_scanner.dart';

const documentQuad = ScanQuad(
  topLeft: ScanPoint(0.2, 0.1),
  topRight: ScanPoint(0.8, 0.1),
  bottomRight: ScanPoint(0.8, 0.9),
  bottomLeft: ScanPoint(0.2, 0.9),
);

class FakeDocumentScanSession implements DocumentScanSession {
  FakeDocumentScanSession({this.detections = const []});

  /// Die Reihe der Erkennungen; danach liefert die Sitzung „nichts erkannt“.
  final List<ScanQuad?> detections;
  Result<ScannedDocument, DocumentScanFailure> captureResult = Success(
    ScannedDocument(bytes: Uint8List.fromList([1, 2, 3])),
  );
  ScanQuad? capturedWith;
  var captureCalls = 0;
  var closed = false;
  var _next = 0;

  @override
  String get previewId => 'preview-1';

  @override
  double get aspectRatio => 4 / 3;

  @override
  Future<ScanQuad?> detect() async {
    return _next < detections.length ? detections[_next++] : null;
  }

  @override
  Future<Result<ScannedDocument, DocumentScanFailure>> capture(
    ScanQuad? quad,
  ) async {
    captureCalls++;
    capturedWith = quad;
    return captureResult;
  }

  @override
  Future<void> close() async => closed = true;
}

class FakeDocumentScanner implements DocumentScanner {
  FakeDocumentScanner(this.result);

  final Result<DocumentScanSession, DocumentScanFailure> result;
  var opens = 0;

  @override
  Future<Result<DocumentScanSession, DocumentScanFailure>> open() async {
    opens++;
    return result;
  }
}
