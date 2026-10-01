import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/transfer_archive.dart';
import '../../domain/entities/transfer_failure.dart';
import '../../domain/repositories/transfer_file_gateway.dart';

/// `saveFile` schreibt die Bytes auf Desktop selbst und löst im Web einen
/// Download aus (file_picker ≥ 11).
class FilePickerTransferFileGateway implements TransferFileGateway {
  const FilePickerTransferFileGateway();

  @override
  Future<Result<Unit, TransferFailure>> save(TransferArchive archive) async {
    try {
      final savedPath = await FilePicker.saveFile(
        dialogTitle: 'Export speichern',
        fileName: archive.fileName,
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: archive.bytes,
      );
      // Im Web startet `saveFile` einen Download und liefert immer `null`.
      if (savedPath == null && !kIsWeb) {
        return const Error(TransferFailure.cancelled());
      }
      return Success.unit();
    } on Object {
      return const Error(_saveFailed);
    }
  }

  @override
  Future<Result<TransferArchive, TransferFailure>> pick() async {
    try {
      final selection = await FilePicker.pickFiles(
        dialogTitle: 'Export-Datei auswählen',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        withData: true,
      );
      final file = selection?.files.singleOrNull;
      if (file == null) return const Error(TransferFailure.cancelled());
      final bytes = file.bytes;
      if (bytes == null) return const Error(_readFailed);
      return Success(TransferArchive(fileName: file.name, bytes: bytes));
    } on Object {
      return const Error(_readFailed);
    }
  }
}

const _saveFailed = TransferFailure(
  TransferFailureKind.failed,
  'Die Export-Datei konnte nicht gespeichert werden.',
);

const _readFailed = TransferFailure(
  TransferFailureKind.failed,
  'Die ausgewählte Datei konnte nicht gelesen werden.',
);
