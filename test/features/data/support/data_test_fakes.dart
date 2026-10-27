import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/data/domain/entities/data_collection.dart';
import 'package:syscat2/features/data/domain/entities/data_collection_name.dart';
import 'package:syscat2/features/data/domain/entities/data_failure.dart';
import 'package:syscat2/features/data/domain/entities/data_file.dart';
import 'package:syscat2/features/data/domain/entities/data_filter.dart';
import 'package:syscat2/features/data/domain/entities/data_import_preview.dart';
import 'package:syscat2/features/data/domain/entities/data_record.dart';
import 'package:syscat2/features/data/domain/entities/data_record_query.dart';
import 'package:syscat2/features/data/domain/entities/data_sort.dart';
import 'package:syscat2/features/data/domain/repositories/data_collection_repository.dart';
import 'package:syscat2/features/data/domain/repositories/data_file_gateway.dart';
import 'package:syscat2/features/data/domain/repositories/data_repository.dart';
import 'package:syscat2/features/data/domain/repositories/data_transfer_repository.dart';

DataCollection dataCollection(String name, {int count = 0}) => DataCollection(
  name: name,
  documentCount: count,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

DataRecord dataRecord(String id, Map<String, Object?> fields) => DataRecord(
  id: id,
  fields: fields,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

/// Datensätze im Speicher; merkt sich die letzte Abfrage.
class FakeDataRepository implements DataRepository {
  List<DataCollection> collections = [dataCollection('Kunden')];
  final records = <DataRecord>[];
  Map<String, Object?>? createdFields;
  Map<String, Object?>? updatedFields;
  String lastSearch = '';
  List<DataFilter> lastFilters = const [];
  DataSort? lastSort;

  DataCollection get collection => collections.first;

  @override
  Future<List<DataCollection>> listCollections() async => List.of(collections);

  @override
  Future<List<DataRecord>> queryRecords({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
    DataSort? sort,
  }) async {
    lastSearch = search;
    lastFilters = filters;
    lastSort = sort;
    return List.of(records);
  }

  @override
  Future<DataRecord> createRecord({
    required String collectionName,
    required Map<String, Object?> fields,
  }) async {
    createdFields = fields;
    final record = dataRecord('record.${records.length + 1}', fields);
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
    final updated = dataRecord(record.id, fields);
    records[records.indexWhere((item) => item.id == record.id)] = updated;
    return updated;
  }

  @override
  Future<void> deleteRecord({
    required String collectionName,
    required DataRecord record,
  }) async => records.removeWhere((item) => item.id == record.id);
}

/// Sammlungsverwaltung im Speicher; [failure] lässt den nächsten Aufruf scheitern.
class FakeDataCollectionRepository implements DataCollectionRepository {
  final calls = <String>[];
  DataFailure? failure;

  Future<Result<T, DataFailure>> _answer<T extends Object>(
    String call,
    T value,
  ) async {
    calls.add(call);
    final pending = failure;
    failure = null;
    return pending == null ? Success(value) : Error(pending);
  }

  @override
  Future<Result<DataCollection, DataFailure>> create(DataCollectionName name) =>
      _answer('create ${name.value}', dataCollection(name.value));

  @override
  Future<Result<DataCollection, DataFailure>> rename(
    DataCollection collection,
    DataCollectionName name,
  ) => _answer(
    'rename ${collection.name} → ${name.value}',
    dataCollection(name.value),
  );

  @override
  Future<Result<Unit, DataFailure>> delete(DataCollection collection) =>
      _answer('delete ${collection.name}', unit);

  @override
  Future<Result<int, DataFailure>> clear(DataCollection collection) =>
      _answer('clear ${collection.name}', collection.documentCount);

  @override
  Future<Result<int, DataFailure>> deleteRecords(
    DataCollection collection,
    List<DataRecord> records,
  ) => _answer(
    'deleteRecords ${records.map((r) => r.id).join(',')}',
    records.length,
  );
}

class FakeDataTransferRepository implements DataTransferRepository {
  DataImportPreview preview = const DataImportPreview(
    count: 2,
    fields: ['name'],
    renamedFields: [],
    sample: [
      {'name': 'Ada'},
    ],
    issues: [],
  );
  DataFailure? failure;
  DataRecordQuery? lastExportQuery;
  int imported = 0;

  @override
  Future<Result<Uint8List, DataFailure>> export(
    DataCollection collection,
    DataFileFormat format,
    DataRecordQuery query,
  ) async {
    lastExportQuery = query;
    return failure == null
        ? Success(Uint8List.fromList([1, 2]))
        : Error(failure!);
  }

  @override
  Future<Result<DataImportPreview, DataFailure>> previewImport(
    DataCollection collection,
    DataFile file,
  ) async => failure == null ? Success(preview) : Error(failure!);

  @override
  Future<Result<int, DataFailure>> importRecords(
    DataCollection collection,
    DataFile file,
  ) async {
    imported = preview.count;
    return Success(preview.count);
  }
}

class FakeDataFileGateway implements DataFileGateway {
  Result<DataFile, DataFailure> picked = Success(
    DataFile(
      name: 'kunden.csv',
      bytes: Uint8List.fromList('name\nAda'.codeUnits),
    ),
  );
  Result<Unit, DataFailure> saveResult = Success.unit();
  DataFile? saved;

  @override
  Future<Result<DataFile, DataFailure>> pickImportFile() async => picked;

  @override
  Future<Result<Unit, DataFailure>> save(DataFile file) async {
    saved = file;
    return saveResult;
  }
}
