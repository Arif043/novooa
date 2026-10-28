import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/file_failure.dart';

/// Legt Bytes als Datei auf dem Gerät ab — Speichern-Dialog am Desktop,
/// Download im Web. Abbruch ist `FileFailureKind.cancelled`.
abstract interface class FileSaveGateway {
  Future<Result<Unit, FileFailure>> save({
    required String fileName,
    required Uint8List bytes,
  });
}
