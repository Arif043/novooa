import '../entities/data_collection.dart';
import '../entities/data_filter.dart';
import '../entities/data_record.dart';

abstract interface class DataRepository {
  Future<List<DataCollection>> listCollections();

  Future<List<DataRecord>> queryRecords({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
  });

  Future<DataRecord> createRecord({
    required String collectionName,
    required Map<String, Object?> fields,
  });

  Future<DataRecord> updateRecord({
    required String collectionName,
    required DataRecord record,
    required Map<String, Object?> fields,
  });

  Future<void> deleteRecord({
    required String collectionName,
    required DataRecord record,
  });
}
