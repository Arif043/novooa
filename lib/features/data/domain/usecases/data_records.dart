import '../entities/data_collection.dart';
import '../entities/data_filter.dart';
import '../entities/data_record.dart';
import '../repositories/data_repository.dart';

class ListDataCollections {
  const ListDataCollections(this._repository);

  final DataRepository _repository;

  Future<List<DataCollection>> call() => _repository.listCollections();
}

class QueryDataRecords {
  const QueryDataRecords(this._repository);

  final DataRepository _repository;

  Future<List<DataRecord>> call({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
  }) => _repository.queryRecords(
    collectionName: collectionName,
    search: search,
    filters: filters,
  );
}

class CreateDataRecord {
  const CreateDataRecord(this._repository);

  final DataRepository _repository;

  Future<DataRecord> call({
    required String collectionName,
    required Map<String, Object?> fields,
  }) =>
      _repository.createRecord(collectionName: collectionName, fields: fields);
}

class UpdateDataRecord {
  const UpdateDataRecord(this._repository);

  final DataRepository _repository;

  Future<DataRecord> call({
    required String collectionName,
    required DataRecord record,
    required Map<String, Object?> fields,
  }) => _repository.updateRecord(
    collectionName: collectionName,
    record: record,
    fields: fields,
  );
}

class DeleteDataRecord {
  const DeleteDataRecord(this._repository);

  final DataRepository _repository;

  Future<void> call({
    required String collectionName,
    required DataRecord record,
  }) =>
      _repository.deleteRecord(collectionName: collectionName, record: record);
}
