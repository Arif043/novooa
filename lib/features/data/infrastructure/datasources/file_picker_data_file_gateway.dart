import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/data_failure.dart';
import '../../domain/entities/data_file.dart';
import '../../domain/repositories/data_file_gateway.dart';

/// `saveFile` schreibt die Bytes auf dem Desktop selbst und löst im Web einen Download aus.
class FilePickerDataFileGateway implements DataFileGateway {
  const FilePickerDataFileGateway();

  @override
  Future<Result<DataFile, DataFailure>> pickImportFile() async {
    try {
      final selection = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: [for (final f in DataFileFormat.values) f.extension],
        withData: true,
      );
      final file = selection?.files.singleOrNull;
      if (file == null) {
        return const Error(DataFailure(DataFailureKind.cancelled));
      }
      final bytes = file.bytes;
      if (bytes == null) {
        return const Error(DataFailure(DataFailureKind.failed));
      }
      return Success(DataFile(name: file.name, bytes: bytes));
    } on Object {
      return const Error(DataFailure(DataFailureKind.failed));
    }
  }

  @override
  Future<Result<Unit, DataFailure>> save(DataFile file) async {
    try {
      final format = file.format;
      final savedPath = await FilePicker.saveFile(
        fileName: file.name,
        type: FileType.custom,
        allowedExtensions: [?format?.extension],
        bytes: file.bytes,
      );
      // Im Web startet `saveFile` einen Download und liefert immer `null`.
      if (savedPath == null && !kIsWeb) {
        return const Error(DataFailure(DataFailureKind.cancelled));
      }
      return Success.unit();
    } on Object {
      return const Error(DataFailure(DataFailureKind.failed));
    }
  }
}
