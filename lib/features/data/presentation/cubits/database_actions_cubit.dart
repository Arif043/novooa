import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_collection_name.dart';
import '../../domain/entities/data_failure.dart';
import '../../domain/entities/data_file.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/entities/data_record_query.dart';
import '../../domain/usecases/data_collections.dart';
import '../../domain/usecases/data_transfer.dart';
import 'database_actions_state.dart';

/// Sammlungen verwalten, Auswahl löschen, exportieren. Liefert das Ergebnis zurück, damit die
/// Seite danach gezielt neu lädt; Rückmeldungen gehen als [DatabaseNotice] an die Snackbar.
class DatabaseActionsCubit extends Cubit<DatabaseActionsState> {
  DatabaseActionsCubit({
    required this._create,
    required this._rename,
    required this._delete,
    required this._clear,
    required this._deleteRecords,
    required this._exportRecords,
  }) : super(const DatabaseActionsState());

  final CreateDataCollection _create;
  final RenameDataCollection _rename;
  final DeleteDataCollection _delete;
  final ClearDataCollection _clear;
  final DeleteDataRecords _deleteRecords;
  final ExportDataRecords _exportRecords;

  Future<DataCollection?> createCollection(DataCollectionName name) => _run(
    () => _create(name),
    (created) => DatabaseNotice(
      DatabaseNoticeKind.collectionCreated,
      name: created.name,
    ),
  );

  Future<DataCollection?> renameCollection(
    DataCollection collection,
    DataCollectionName name,
  ) => _run(
    () => _rename(collection, name),
    (renamed) => DatabaseNotice(
      DatabaseNoticeKind.collectionRenamed,
      name: renamed.name,
    ),
  );

  Future<bool> deleteCollection(DataCollection collection) async =>
      await _run(
        () => _delete(collection),
        (_) => DatabaseNotice(
          DatabaseNoticeKind.collectionDeleted,
          name: collection.name,
        ),
      ) !=
      null;

  Future<bool> clearCollection(DataCollection collection) async =>
      await _run(
        () => _clear(collection),
        (count) => DatabaseNotice(
          DatabaseNoticeKind.collectionCleared,
          name: collection.name,
          count: count,
        ),
      ) !=
      null;

  Future<bool> deleteRecords(
    DataCollection collection,
    List<DataRecord> records,
  ) async =>
      await _run(
        () => _deleteRecords(collection, records),
        (count) =>
            DatabaseNotice(DatabaseNoticeKind.recordsDeleted, count: count),
      ) !=
      null;

  Future<void> export(
    DataCollection collection,
    DataFileFormat format,
    DataRecordQuery query,
  ) => _run(
    () => _exportRecords(collection, format, query),
    (_) => DatabaseNotice(DatabaseNoticeKind.exported, name: collection.name),
  );

  /// Der Import läuft im eigenen Dialog; die Erfolgsmeldung gehört trotzdem hierher.
  void reportImported(int count) => emit(
    DatabaseActionsState(
      notice: DatabaseNotice(DatabaseNoticeKind.recordsImported, count: count),
    ),
  );

  Future<T?> _run<T extends Object>(
    Future<Result<T, DataFailure>> Function() action,
    DatabaseNotice Function(T value) noticeFor,
  ) async {
    emit(const DatabaseActionsState(isBusy: true));
    final valueOrFailure = await action();
    if (isClosed) return null;
    switch (valueOrFailure) {
      case Success(success: final value):
        emit(DatabaseActionsState(notice: noticeFor(value)));
        return value;
      case Error(error: final failure):
        emit(DatabaseActionsState(notice: _failureNotice(failure)));
        return null;
    }
  }

  /// Abbrechen ist keine Störung und braucht keine Meldung.
  DatabaseNotice? _failureNotice(DataFailure failure) =>
      failure.kind == DataFailureKind.cancelled
      ? null
      : DatabaseNotice(DatabaseNoticeKind.failed, failure: failure);
}
