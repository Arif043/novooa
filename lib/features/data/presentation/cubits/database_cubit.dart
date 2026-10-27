import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/entities/data_sort.dart';
import '../../domain/usecases/data_records.dart';
import 'database_state.dart';

part 'database_record_mutations.dart';

class DatabaseCubit extends Cubit<DatabaseState> with _DatabaseRecordMutations {
  DatabaseCubit({
    required this._listCollections,
    required this._queryRecords,
    required this._createRecord,
    required this._updateRecord,
    required this._deleteRecord,
  }) : super(const DatabaseState());

  /// Nach außen geänderte Sammlungen (anlegen, umbenennen, leeren, importieren): Liste neu laden
  /// und [collection] — falls gesetzt — mit frischer Anzahl öffnen.
  Future<void> reload({DataCollection? collection}) async {
    final current = collection ?? state.collection;
    await loadCollections();
    if (current == null || state.status == DatabaseStatus.failure) return;
    final fresh = state.collections.where((item) => item.name == current.name);
    if (fresh.isEmpty) return;
    emit(
      state.copyWith(status: DatabaseStatus.loading, collection: fresh.first),
    );
    await _loadRecords();
  }

  final ListDataCollections _listCollections;
  final QueryDataRecords _queryRecords;
  @override
  final CreateDataRecord _createRecord;
  @override
  final UpdateDataRecord _updateRecord;
  @override
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
        clearSort: true,
        selectedIds: const {},
        clearMessage: true,
      ),
    );
    await _loadRecords();
  }

  Future<void> search(String value) async {
    emit(
      state.copyWith(
        search: value,
        status: DatabaseStatus.loading,
        selectedIds: const {},
      ),
    );
    await _loadRecords();
  }

  Future<void> toggleSort(String field) async {
    if (!DataSort.isSortable(field)) return;
    final sort = DataSort.toggled(state.sort, field);
    emit(state.copyWith(sort: sort, clearSort: sort == null));
    await _loadRecords();
  }

  void toggleSelection(DataRecord record) {
    final ids = {...state.selectedIds};
    if (!ids.remove(record.id)) ids.add(record.id);
    emit(state.copyWith(selectedIds: ids));
  }

  void toggleAllSelected() => emit(
    state.copyWith(
      selectedIds: state.allSelected
          ? const {}
          : {for (final record in state.records) record.id},
    ),
  );

  void clearSelection() => emit(state.copyWith(selectedIds: const {}));

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
    emit(_filtered(filters));
    await _loadRecords();
  }

  Future<void> removeFilter(int index) async {
    final filters = [...state.filters]..removeAt(index);
    emit(_filtered(filters));
    await _loadRecords();
  }

  Future<void> showCollections() => loadCollections();

  @override
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
        sort: state.sort,
      );
      // Gelöschte oder weggefilterte Datensätze verlassen die Auswahl.
      final visible = {for (final record in records) record.id};
      emit(
        state.copyWith(
          status: DatabaseStatus.records,
          records: records,
          selectedIds: state.selectedIds.intersection(visible),
        ),
      );
    } on WorkspaceHttpException catch (error) {
      emit(_failure(error.message));
    } on Object catch (_) {
      emit(_failure('Die Datensätze konnten nicht geladen werden.'));
    }
  }

  DatabaseState _filtered(List<DataFilter> filters) => state.copyWith(
    filters: filters,
    status: DatabaseStatus.loading,
    selectedIds: const {},
  );

  DatabaseState _failure(String message) =>
      state.copyWith(status: DatabaseStatus.failure, message: message);

  @override
  DataCollection get _currentCollection {
    final collection = state.collection;
    if (collection == null) throw StateError('Keine Datensammlung ausgewählt.');
    return collection;
  }
}
