import '../../../../core/network/workspace_api_client.dart';
import '../../domain/entities/data_collection.dart';
import '../../domain/entities/data_filter.dart';
import '../../domain/entities/data_record.dart';
import '../../domain/repositories/data_repository.dart';

class LocalDataRepository implements DataRepository {
  LocalDataRepository(this._client);

  final WorkspaceApiClient _client;

  @override
  Future<List<DataCollection>> listCollections() async {
    final response = await _client.get('/v1/data/collections');
    return _items(response).map(_collectionFrom).toList(growable: false);
  }

  @override
  Future<List<DataRecord>> queryRecords({
    required String collectionName,
    required String search,
    required List<DataFilter> filters,
  }) async {
    final response = await _client.post(
      '${_collectionPath(collectionName)}/query',
      {
        'search': search,
        'filters': filters.map(_filterJson).toList(growable: false),
      },
    );
    return _items(response).map(_recordFrom).toList(growable: false);
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
    return _recordFrom(response);
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
    return _recordFrom(response);
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

  String _collectionPath(String name) =>
      '/v1/data/collections/${Uri.encodeComponent(name)}';

  Map<String, Object?> _filterJson(DataFilter filter) => {
    'field': filter.field,
    'operator': filter.operator.wireName,
    'value': filter.value,
  };
}

DataCollection _collectionFrom(Object? value) {
  final json = _map(value);
  return DataCollection(
    name: _string(json, 'name'),
    documentCount: _int(json, 'documentCount'),
    createdAt: DateTime.parse(_string(json, 'createdAt')),
    updatedAt: DateTime.parse(_string(json, 'updatedAt')),
  );
}

DataRecord _recordFrom(Object? value) {
  final json = _map(value);
  return DataRecord(
    id: _string(json, 'id'),
    fields: _map(json['data']),
    createdAt: DateTime.parse(_string(json, 'createdAt')),
    updatedAt: DateTime.parse(_string(json, 'updatedAt')),
  );
}

List<Object?> _items(Map<String, Object?> response) {
  final items = response['items'];
  if (items is! List) {
    throw const FormatException('Die Runtime lieferte keine Datenliste.');
  }
  return List<Object?>.from(items);
}

Map<String, Object?> _map(Object? value) {
  if (value is! Map) {
    throw const FormatException('Die Runtime lieferte ungültige Daten.');
  }
  return {for (final entry in value.entries) entry.key.toString(): entry.value};
}

String _string(Map<String, Object?> value, String key) {
  final item = value[key];
  if (item is! String) {
    throw const FormatException('Die Runtime lieferte ungültige Daten.');
  }
  return item;
}

int _int(Map<String, Object?> value, String key) {
  final item = value[key];
  if (item is int) return item;
  if (item is num) return item.toInt();
  throw const FormatException('Die Runtime lieferte ungültige Daten.');
}
