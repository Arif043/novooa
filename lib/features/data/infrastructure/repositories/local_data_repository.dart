import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/entities/data_record_query.dart';
import '../../domain/entities/data_sort.dart';
import '../../domain/repositories/data_repository.dart';
import 'data_json_reader.dart';
import 'data_request_json.dart';

class LocalDataRepository implements DataRepository {
  LocalDataRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<List<DataCollection>> listCollections() async {
    final response = await _client.get('/v1/data/collections');
    return jsonItems(
      response,
    ).map(dataCollectionFromJson).toList(growable: false);
  }

  @override
  Future<List<DataRecord>> queryRecords({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
    DataSort? sort,
  }) async {
    final response = await _client.post(
      '${_collectionPath(collectionName)}/query',
      dataQueryJson(
        DataRecordQuery(search: search, filters: filters, sort: sort),
      ),
    );
    return jsonItems(response).map(dataRecordFromJson).toList(growable: false);
  }

  @override
  Future<DataRecord> createRecord({
    required String collectionName,
    required Map<String, Object?> fields,
  }) async {
    final response = await _client.post(
      '${_collectionPath(collectionName)}/documents',
      {'data': fields},
    );
    return dataRecordFromJson(response);
  }

  @override
  Future<DataRecord> updateRecord({
    required String collectionName,
    required DataRecord record,
    required Map<String, Object?> fields,
  }) async {
    final response = await _client.put(
      '${_collectionPath(collectionName)}/documents/${Uri.encodeComponent(record.id)}',
      {'data': fields},
    );
    return dataRecordFromJson(response);
  }

  @override
  Future<void> deleteRecord({
    required String collectionName,
    required DataRecord record,
  }) {
    return _client
        .delete(
          '${_collectionPath(collectionName)}/documents/${Uri.encodeComponent(record.id)}',
        )
        .then((_) {});
  }

  String _collectionPath(String name) => dataCollectionPath(name);
}
