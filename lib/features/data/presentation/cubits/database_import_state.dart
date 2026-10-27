import '../../domain/entities/data_failure.dart';
import '../../domain/entities/data_file.dart';
import '../../domain/entities/data_import_preview.dart';

enum DatabaseImportStep {
  picking,
  previewing,
  preview,
  importing,
  done,
  cancelled,
  failed,
}

class DatabaseImportState {
  const DatabaseImportState({
    this.step = DatabaseImportStep.picking,
    this.file,
    this.preview,
    this.failure,
    this.importedCount = 0,
  });

  final DatabaseImportStep step;
  final DataFile? file;
  final DataImportPreview? preview;
  final DataFailure? failure;
  final int importedCount;

  bool get isWorking =>
      step == DatabaseImportStep.picking ||
      step == DatabaseImportStep.previewing ||
      step == DatabaseImportStep.importing;

  DatabaseImportState copyWith({
    required DatabaseImportStep step,
    DataFile? file,
    DataImportPreview? preview,
    DataFailure? failure,
    int? importedCount,
  }) => DatabaseImportState(
    step: step,
    file: file ?? this.file,
    preview: preview ?? this.preview,
    failure: failure,
    importedCount: importedCount ?? this.importedCount,
  );
}
