import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/upload_file_input.dart';

/// Lässt Nutzer:innen eine Datei wählen; `null`, wenn nichts gewählt wurde.
Future<UploadFileInput?> pickUploadFile() async {
  final pickedFileOrFailure = await FilePicker.pickFiles(withData: true);
  final file = pickedFileOrFailure?.files.firstOrNull;
  final bytes = file?.bytes;
  if (file == null || bytes == null) return null;
  return UploadFileInput(
    name: file.name,
    bytes: Uint8List.fromList(bytes),
    sizeBytes: file.size,
    contentType: _contentTypeFor(file.extension),
  );
}

String _contentTypeFor(String? extension) {
  return switch (extension?.toLowerCase()) {
    'pdf' => 'application/pdf',
    'txt' => 'text/plain',
    'json' => 'application/json',
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'xlsx' =>
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    _ => 'application/octet-stream',
  };
}
