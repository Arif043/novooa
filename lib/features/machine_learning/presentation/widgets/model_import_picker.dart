import 'dart:convert';

import 'package:file_picker/file_picker.dart';

import '../../domain/entities/model_catalog_import.dart';

class ModelImportPicker {
  static Future<ModelCatalogImport?> pick() async {
    final artifactBytes = await _bytesFor(const ['onnx']);
    if (artifactBytes == null) return null;
    if (artifactBytes.length > _maximumArtifactBytes) {
      throw const FormatException(
        'Die ONNX-Datei darf höchstens 50 MB groß sein.',
      );
    }
    final manifestBytes = await _bytesFor(const ['json']);
    if (manifestBytes == null) return null;
    return ModelCatalogImport(
      manifestJson: utf8.decode(manifestBytes),
      artifactBytes: artifactBytes,
    );
  }

  static const _maximumArtifactBytes = 50 * 1024 * 1024;

  static Future<List<int>?> _bytesFor(List<String> extensions) async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: extensions,
      withData: true,
    );
    return selection?.files.singleOrNull?.bytes;
  }
}
