import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/data/domain/entities/data_collection.dart';
import 'package:syscat2/features/data/domain/entities/data_filter.dart';
import 'package:syscat2/features/data/domain/entities/data_record.dart';
import 'package:syscat2/features/data/domain/repositories/data_repository.dart';
import 'package:syscat2/features/data/domain/usecases/data_records.dart';
import 'package:syscat2/features/data/presentation/cubits/database_cubit.dart';

void main() {
  test('legt, aktualisiert und loescht Datensaetze ueber den Cubit', () async {
    final repository = _DataRepository();
    final cubit = _cubit(repository);
    await cubit.loadCollections();
    await cubit.openCollection(repository.collection);

    await cubit.createRecord({'name': 'Ada'});
    final created = repository.records.single;
    await cubit.updateRecord(created, {'name': 'Grace'});
    await cubit.deleteRecord(repository.records.single);

    expect(repository.createdFields, {'name': 'Ada'});
    expect(repository.updatedFields, {'name': 'Grace'});
    expect(repository.records, isEmpty);
    await cubit.close();
  });

  test('wendet Suche und Filter auf die Abfrage an', () async {
    final repository = _DataRepository();
    final cubit = _cubit(repository);
    await cubit.openCollection(repository.collection);
    cubit.addFilter();
    await cubit.changeFilter(
      0,
      const DataFilter(
        field: 'status',
        operator: DataFilterOperator.equals,
        value: 'offen',
      ),
    );
    await cubit.search('Ada');

    expect(repository.lastSearch, 'Ada');
    expect(repository.lastFilters.single.field, 'status');
    await cubit.close();
  });
}

DatabaseCubit _cubit(_DataRepository repository) => DatabaseCubit(
  listCollections: ListDataCollections(repository),
  queryRecords: QueryDataRecords(repository),
  createRecord: CreateDataRecord(repository),
  updateRecord: UpdateDataRecord(repository),
  deleteRecord: DeleteDataRecord(repository),
);

class _DataRepository implements DataRepository {
  final collection = DataCollection(
    name: 'Kunden',
    documentCount: 0,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
  final records = <DataRecord>[];
  Map<String, Object?>? createdFields;
  Map<String, Object?>? updatedFields;
  String lastSearch = '';
  List<DataFilter> lastFilters = const [];

  @override
  Future<List<DataCollection>> listCollections() async => [collection];

  @override
  Future<List<DataRecord>> queryRecords({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
  }) async {
    lastSearch = search;
    lastFilters = filters;
    return List.of(records);
  }

  @override
  Future<DataRecord> createRecord({
    required String collectionName,
    required Map<String, Object?> fields,
  }) async {
    createdFields = fields;
    final record = DataRecord(
      id: 'record.${records.length + 1}',
      fields: fields,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );
    records.add(record);
    return record;
  }

  @override
  Future<DataRecord> updateRecord({
    required String collectionName,
    required DataRecord record,
    required Map<String, Object?> fields,
  }) async {
    updatedFields = fields;
    final updated = DataRecord(
      id: record.id,
      fields: fields,
      createdAt: record.createdAt,
      updatedAt: DateTime.utc(2026, 2),
    );
    records[records.indexWhere((item) => item.id == record.id)] = updated;
    return updated;
  }

  @override
  Future<void> deleteRecord({
    required String collectionName,
    required DataRecord record,
  }) async {
    records.removeWhere((item) => item.id == record.id);
  }
}
