import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/file_failure.dart';
import '../../domain/repositories/file_save_gateway.dart';

/// `saveFile` schreibt die Bytes auf dem Desktop selbst und löst im Web
/// einen Download aus.
class FilePickerFileSaveGateway implements FileSaveGateway {
  const FilePickerFileSaveGateway();

  @override
  Future<Result<Unit, FileFailure>> save({
    required String fileName,
    required Uint8List bytes,
  }) async {
    try {
      final savedPath = await FilePicker.saveFile(
        fileName: fileName,
        bytes: bytes,
      );
      // Im Web startet `saveFile` einen Download und liefert immer `null`.
      if (savedPath == null && !kIsWeb) {
        return const Error(FileFailure(FileFailureKind.cancelled));
      }
      return Success.unit();
    } on Object {
      return const Error(FileFailure(FileFailureKind.saveFailed));
    }
  }
}
