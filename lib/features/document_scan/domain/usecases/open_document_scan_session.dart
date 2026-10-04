import 'package:multiple_result/multiple_result.dart';

import '../entities/document_scan_failure.dart';
import '../repositories/document_scanner.dart';

class OpenDocumentScanSession {
  const OpenDocumentScanSession(this._scanner);

  final DocumentScanner _scanner;

  Future<Result<DocumentScanSession, DocumentScanFailure>> call() {
    return _scanner.open();
  }
}
