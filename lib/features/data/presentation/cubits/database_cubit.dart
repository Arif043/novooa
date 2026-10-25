import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/usecases/data_records.dart';
import 'database_state.dart';

class DatabaseCubit extends Cubit<DatabaseState> {
  DatabaseCubit({
    required ListDataCollections listCollections,
    required QueryDataRecords queryRecords,
    required CreateDataRecord createRecord,
    required UpdateDataRecord updateRecord,
    required DeleteDataRecord deleteRecord,
  }) : _listCollections = listCollections,
       _queryRecords = queryRecords,
       _createRecord = createRecord,
       _updateRecord = updateRecord,
       _deleteRecord = deleteRecord,
       super(const DatabaseState());

  final ListDataCollections _listCollections;
  final QueryDataRecords _queryRecords;
  final CreateDataRecord _createRecord;
  final UpdateDataRecord _updateRecord;
  final DeleteDataRecord _deleteRecord;

  Future<void> loadCollections() async {
    emit(state.copyWith(status: DatabaseStatus.loading, clearMessage: true));
    try {
      final collections = await _listCollections();
      emit(
        state.copyWith(
          status: DatabaseStatus.collections,
          collections: collections,
        ),
      );
    } on Object catch (_) {
      emit(_failure('Die Datensammlungen konnten nicht geladen werden.'));
    }
  }

  Future<void> openCollection(DataCollection collection) async {
    emit(
      state.copyWith(
        status: DatabaseStatus.loading,
        collection: collection,
        records: const [],
        search: '',
        filters: const [],
        clearMessage: true,
      ),
    );
    await _loadRecords();
  }

  Future<void> search(String value) async {
    emit(state.copyWith(search: value, status: DatabaseStatus.loading));
    await _loadRecords();
  }

  void addFilter() {
    emit(
      state.copyWith(
        filters: [
          ...state.filters,
          const DataFilter(
            field: '',
            operator: DataFilterOperator.equals,
            value: '',
          ),
        ],
      ),
    );
  }

  Future<void> changeFilter(int index, DataFilter filter) async {
    final filters = [...state.filters]..[index] = filter;
    emit(state.copyWith(filters: filters, status: DatabaseStatus.loading));
    await _loadRecords();
  }

  Future<void> removeFilter(int index) async {
    final filters = [...state.filters]..removeAt(index);
    emit(state.copyWith(filters: filters, status: DatabaseStatus.loading));
    await _loadRecords();
  }

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

  Future<void> showCollections() => loadCollections();

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

  Future<void> _loadRecords() async {
    final collection = state.collection;
    if (collection == null) return;
    try {
      final records = await _queryRecords(
        collectionName: collection.name,
        search: state.search,
        filters: state.filters
            .where((filter) => filter.field.trim().isNotEmpty)
            .toList(growable: false),
      );
      emit(state.copyWith(status: DatabaseStatus.records, records: records));
    } on WorkspaceHttpException catch (error) {
      emit(_failure(error.message));
    } on Object catch (_) {
      emit(_failure('Die Datensätze konnten nicht geladen werden.'));
    }
  }

  DatabaseState _failure(String message) =>
      state.copyWith(status: DatabaseStatus.failure, message: message);

  DataCollection get _currentCollection {
    final collection = state.collection;
    if (collection == null) throw StateError('Keine Datensammlung ausgewählt.');
    return collection;
  }
}
