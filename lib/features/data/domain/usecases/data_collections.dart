import 'package:multiple_result/multiple_result.dart';

import '../entities/data_collection.dart';
import '../entities/data_collection_name.dart';
import '../entities/data_failure.dart';
import '../entities/data_record.dart';
import '../repositories/data_collection_repository.dart';

class CreateDataCollection {
  const CreateDataCollection(this._repository);

  final DataCollectionRepository _repository;

  Future<Result<DataCollection, DataFailure>> call(DataCollectionName name) =>
      _repository.create(name);
}

class RenameDataCollection {
  const RenameDataCollection(this._repository);

  final DataCollectionRepository _repository;

  Future<Result<DataCollection, DataFailure>> call(
    DataCollection collection,
    DataCollectionName name,
  ) => _repository.rename(collection, name);
}

class DeleteDataCollection {
  const DeleteDataCollection(this._repository);

  final DataCollectionRepository _repository;

  Future<Result<Unit, DataFailure>> call(DataCollection collection) =>
      _repository.delete(collection);
}

class ClearDataCollection {
  const ClearDataCollection(this._repository);

  final DataCollectionRepository _repository;

  Future<Result<int, DataFailure>> call(DataCollection collection) =>
      _repository.clear(collection);
}

class DeleteDataRecords {
  const DeleteDataRecords(this._repository);

  final DataCollectionRepository _repository;

  /// Ohne Auswahl gibt es nichts zu tun — kein Aufruf an die Runtime.
  Future<Result<int, DataFailure>> call(
    DataCollection collection,
    List<DataRecord> records,
  ) async {
    if (records.isEmpty) return const Success(0);
    return _repository.deleteRecords(collection, records);
  }
}
