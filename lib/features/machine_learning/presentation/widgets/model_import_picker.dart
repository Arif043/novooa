import "dart:convert";

import "package:easy_localization/easy_localization.dart";
import "package:file_picker/file_picker.dart";
import "package:syscat2/core/localization/locale_keys.g.dart";

import "../../domain/entities/model_catalog_import.dart";

/// Wählt Modell, Gewichtsdateien und Manifest. Eine Größengrenze gibt es hier nicht:
/// Die Dateien werden gestreamt, und die Runtime prüft den freien Platz selbst.
class ModelImportPicker {
  static Future<ModelCatalogImport?> pick() async {
    final files = await _modelFiles();
    if (files == null) return null;
    final manifestBytes = await _manifestBytes();
    if (manifestBytes == null) return null;
    final model = files.firstWhere(_isModel);
    return ModelCatalogImport(
      manifestJson: utf8.decode(manifestBytes),
      artifactLength: model.size,
      openArtifact: () => model.readStream!,
      weights: files.where((file) => !_isModel(file)).map(_weight).toList(),
    );
  }

  /// Modell und Gewichte in einem Schritt: genau eine .onnx-Datei, alle übrigen sind Gewichte.
  static Future<List<PlatformFile>?> _modelFiles() async {
    final selection = await FilePicker.pickFiles(
      dialogTitle: LocaleKeys.machine_learning_model_import_select_files_hint
          .tr(),
      allowMultiple: true,
      withReadStream: true,
    );
    final files = selection?.files;
    if (files == null || files.isEmpty) return null;
    if (files.where(_isModel).length != 1) {
      throw FormatException(
        LocaleKeys.machine_learning_model_import_exactly_one_model.tr(),
      );
    }
    files.forEach(_requireReadable);
    return files;
  }

  static ModelImportFile _weight(PlatformFile file) => ModelImportFile(
    name: file.name,
    length: file.size,
    open: () => file.readStream!,
  );

  static bool _isModel(PlatformFile file) =>
      file.name.toLowerCase().endsWith(".onnx");

  static void _requireReadable(PlatformFile file) {
    if (file.readStream != null) return;
    throw FormatException(
      LocaleKeys.machine_learning_model_import_unreadable_file.tr(
        namedArgs: {"name": file.name},
      ),
    );
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
