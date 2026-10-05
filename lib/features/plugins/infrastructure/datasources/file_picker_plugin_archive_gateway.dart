import 'package:file_picker/file_picker.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/plugin_failure.dart';
import '../../domain/repositories/plugin_archive_gateway.dart';

class FilePickerPluginArchiveGateway implements PluginArchiveGateway {
  const FilePickerPluginArchiveGateway();

  static const _readFailed = PluginFailure(
    'Die Datei konnte nicht gelesen werden.',
  );

  @override
  Future<Result<PluginArchive, PluginFailure>> pick() async {
    try {
      final selection = await FilePicker.pickFiles(
        dialogTitle: 'Plugin-ZIP auswählen',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        withData: true,
      );
      final file = selection?.files.singleOrNull;
      if (file == null) return const Error(PluginFailure.cancelled);
      final bytes = file.bytes;
      if (bytes == null) return const Error(_readFailed);
      return Success(PluginArchive(fileName: file.name, bytes: bytes));
    } on Object {
      return const Error(_readFailed);
    }
  }
}
