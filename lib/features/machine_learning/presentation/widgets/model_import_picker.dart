import "dart:convert";

import "package:file_picker/file_picker.dart";

import "../../domain/entities/model_catalog_import.dart";

class ModelImportPicker {
  static const _maximumArtifactBytes = 2 * 1024 * 1024 * 1024;

  static Future<ModelCatalogImport?> pick() async {
    final artifact = await _artifact();
    if (artifact == null) return null;
    final manifestBytes = await _manifestBytes();
    if (manifestBytes == null) return null;
    return ModelCatalogImport(
      manifestJson: utf8.decode(manifestBytes),
      artifactLength: artifact.size,
      openArtifact: () => artifact.readStream!,
    );
  }

  static Future<PlatformFile?> _artifact() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["onnx"],
      withReadStream: true,
    );
    final artifact = selection?.files.singleOrNull;
    if (artifact == null) return null;
    if (artifact.size > _maximumArtifactBytes) {
      throw const FormatException(
        "Die ONNX-Datei darf höchstens 2 GiB groß sein.",
      );
    }
    if (artifact.readStream == null) {
      throw const FormatException(
        "Die ONNX-Datei konnte nicht gelesen werden.",
      );
    }
    return artifact;
  }

  static Future<List<int>?> _manifestBytes() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ["json"],
      withData: true,
    );
    return selection?.files.singleOrNull?.bytes;
  }
}
