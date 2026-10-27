import 'package:multiple_result/multiple_result.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_collection_name.dart';
import '../../domain/entities/data_failure.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/repositories/data_collection_repository.dart';
import 'data_failure_mapping.dart';
import 'data_json_reader.dart';
import 'data_request_json.dart';

class LocalDataCollectionRepository implements DataCollectionRepository {
  LocalDataCollectionRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<Result<DataCollection, DataFailure>> create(DataCollectionName name) =>
      dataResultOf(() async {
        final response = await _client.post('/v1/data/collections', {
          'name': name.value,
        });
        return dataCollectionFromJson(response);
      });

  @override
  Future<Result<DataCollection, DataFailure>> rename(
    DataCollection collection,
    DataCollectionName name,
  ) => dataResultOf(() async {
    final response = await _client.put(dataCollectionPath(collection.name), {
      'name': name.value,
    });
    return dataCollectionFromJson(response);
  });

  @override
  Future<Result<Unit, DataFailure>> delete(DataCollection collection) =>
      dataResultOf(() async {
        await _client.delete(dataCollectionPath(collection.name));
        return unit;
      });

  @override
  Future<Result<int, DataFailure>> clear(DataCollection collection) =>
      dataResultOf(() async {
        final response = await _client.delete(
          '${dataCollectionPath(collection.name)}/documents',
        );
        return jsonInt(response, 'deleted');
      });

  @override
  Future<Result<int, DataFailure>> deleteRecords(
    DataCollection collection,
    List<DataRecord> records,
  ) => dataResultOf(() async {
    final response = await _client.post(
      '${dataCollectionPath(collection.name)}/documents/delete',
      {'ids': records.map((record) => record.id).toList(growable: false)},
    );
    return jsonInt(response, 'deleted');
  });
}
