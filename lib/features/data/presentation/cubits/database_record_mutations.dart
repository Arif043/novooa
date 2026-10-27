part of 'database_cubit.dart';

/// Datensätze einzeln anlegen, ändern und löschen; danach lädt der Cubit die Ansicht neu.
mixin _DatabaseRecordMutations on Cubit<DatabaseState> {
  CreateDataRecord get _createRecord;
  UpdateDataRecord get _updateRecord;
  DeleteDataRecord get _deleteRecord;
  DataCollection get _currentCollection;
  Future<void> _loadRecords();

  Future<void> createRecord(Map<String, Object?> fields) => _mutate(() async {
    final collection = _currentCollection;
    await _createRecord(collectionName: collection.name, fields: fields);
  }, 'Der Datensatz wurde angelegt.');

  Future<void> updateRecord(DataRecord record, Map<String, Object?> fields) =>
      _mutate(() async {
        final collection = _currentCollection;
        await _updateRecord(
          collectionName: collection.name,
          record: record,
          fields: fields,
        );
      }, 'Der Datensatz wurde gespeichert.');

  Future<void> deleteRecord(DataRecord record) => _mutate(() async {
    final collection = _currentCollection;
    await _deleteRecord(collectionName: collection.name, record: record);
  }, 'Der Datensatz wurde gelöscht.');

  Future<void> _mutate(Future<void> Function() action, String message) async {
    emit(state.copyWith(isMutating: true, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(isMutating: false, message: message));
      await _loadRecords();
    } on WorkspaceHttpException catch (error) {
      emit(state.copyWith(isMutating: false, message: error.message));
    } on Object catch (_) {
      emit(
        state.copyWith(
          isMutating: false,
          message: 'Die Daten konnten nicht gespeichert werden.',
        ),
      );
    }
  }
}
