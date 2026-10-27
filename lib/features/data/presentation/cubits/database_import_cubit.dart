import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_failure.dart';
import '../../domain/usecases/data_transfer.dart';
import 'database_import_state.dart';

/// Erzeugt den Import-Cubit für eine Sammlung — die Seite stellt ihn bereit, Tests ersetzen ihn.
typedef DatabaseImportCubitFactory =
    DatabaseImportCubit Function(DataCollection collection);

/// Import in eine Sammlung: Datei wählen → Vorschau der Runtime → übernehmen.
class DatabaseImportCubit extends Cubit<DatabaseImportState> {
  DatabaseImportCubit({
    required this.collection,
    required this._pickFile,
    required this._preview,
    required this._importRecords,
  }) : super(const DatabaseImportState());

  final DataCollection collection;
  final PickDataImportFile _pickFile;
  final PreviewDataImport _preview;
  final ImportDataRecords _importRecords;

  Future<void> start() async {
    emit(const DatabaseImportState());
    final fileOrFailure = await _pickFile();
    if (isClosed) return;
    switch (fileOrFailure) {
      case Error(error: final failure):
        _fail(failure);
      case Success(success: final file):
        emit(state.copyWith(step: DatabaseImportStep.previewing, file: file));
        final previewOrFailure = await _preview(collection, file);
        if (isClosed) return;
        switch (previewOrFailure) {
          case Success(success: final preview):
            emit(
              state.copyWith(
                step: DatabaseImportStep.preview,
                preview: preview,
              ),
            );
          case Error(error: final failure):
            _fail(failure);
        }
    }
  }

  Future<void> confirm() async {
    final file = state.file;
    if (file == null || state.preview?.canImport != true) return;
    emit(state.copyWith(step: DatabaseImportStep.importing));
    final countOrFailure = await _importRecords(collection, file);
    if (isClosed) return;
    switch (countOrFailure) {
      case Success(success: final count):
        emit(
          state.copyWith(step: DatabaseImportStep.done, importedCount: count),
        );
      case Error(error: final failure):
        _fail(failure);
    }
  }

  void _fail(DataFailure failure) => emit(
    state.copyWith(
      step: failure.kind == DataFailureKind.cancelled
          ? DatabaseImportStep.cancelled
          : DatabaseImportStep.failed,
      failure: failure,
    ),
  );
}
