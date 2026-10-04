import '../../domain/entities/document_scan_failure.dart';
import '../../domain/entities/scan_quad.dart';
import '../../domain/entities/scanned_document.dart';

/// Zustände des Scanners; die Oberfläche behandelt jeden in einem
/// erschöpfenden `switch`.
sealed class DocumentScanState {
  const DocumentScanState();
}

class DocumentScanOpening extends DocumentScanState {
  const DocumentScanOpening();
}

/// Das Kamerabild läuft; [quad] ist das erkannte Dokument, falls es eines gibt.
class DocumentScanScanning extends DocumentScanState {
  const DocumentScanScanning({
    required this.previewId,
    required this.aspectRatio,
    this.quad,
  });

  final String previewId;
  final double aspectRatio;
  final ScanQuad? quad;
}

class DocumentScanCapturing extends DocumentScanState {
  const DocumentScanCapturing({
    required this.previewId,
    required this.aspectRatio,
    this.quad,
  });

  final String previewId;
  final double aspectRatio;
  final ScanQuad? quad;
}

class DocumentScanReview extends DocumentScanState {
  const DocumentScanReview(this.document);

  final ScannedDocument document;
}

class DocumentScanFailed extends DocumentScanState {
  const DocumentScanFailed(this.failure);

  final DocumentScanFailure failure;
}
