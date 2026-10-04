import 'package:multiple_result/multiple_result.dart';

import '../domain/entities/document_scan_failure.dart';
import '../domain/repositories/document_scanner.dart';

/// Für Plattformen ohne Browser-Scanner. Auf Android und iOS scannt das native
/// Plugin in der Medien-Aufnahme, nicht diese Klasse.
DocumentScanner createDocumentScanner() => const _UnavailableDocumentScanner();

class _UnavailableDocumentScanner implements DocumentScanner {
  const _UnavailableDocumentScanner();

  @override
  Future<Result<DocumentScanSession, DocumentScanFailure>> open() async {
    return const Error(
      DocumentScanFailure(DocumentScanFailureKind.unsupported),
    );
  }
}
