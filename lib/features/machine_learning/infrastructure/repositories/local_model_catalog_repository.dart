import 'dart:convert';

import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

import '../../domain/entities/model_cache_status.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/repositories/model_catalog_repository.dart';
import '../mappers/model_catalog_entry_mapper.dart';

const _installTimeout = Duration(minutes: 30);

class LocalModelCatalogRepository
    implements ModelCatalogRepository, GlobalModelCatalogRepository {
  const LocalModelCatalogRepository(
    this._client,
    this._channel, [
    this._mapper = const ModelCatalogEntryMapper(),
  ]);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;
  final ModelCatalogEntryMapper _mapper;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    final manifest = _manifestFrom(value.manifestJson);
    final import = await _client.post('/v1/ml-models/imports', {
      'manifest': manifest,
    });
    final importPath =
        '/v1/ml-models/imports/${Uri.encodeComponent(_importIdFrom(import))}';
    // Gewichte zuerst: Der Modell-Upload schließt den Import ab und installiert alles zusammen.
    for (final weight in value.weights) {
      await _upload(
        '$importPath/external-data/${Uri.encodeComponent(weight.name)}',
        weight.open(),
        weight.length,
      );
    }
    await _upload(
      '$importPath/artifact',
      value.openArtifact(),
      value.artifactLength,
    );
  }

  Future<void> _upload(String path, Stream<List<int>> body, int length) {
    return _client.putStream(
      path,
      body: body,
      contentLength: length,
      contentType: 'application/onnx',
      // Die Frist beginnt nach dem Senden; danach schreibt die Runtime große Dateien noch um.
      timeout: _installTimeout,
    );
  }

  @override
  Future<void> removeEntry(String modelId) {
    return _client.delete('/v1/ml-models/${Uri.encodeComponent(modelId)}');
  }

  @override
  Future<List<ModelCatalogEntry>> loadGlobalEntries() async {
    final response = await _client.get('/v1/ml-models/catalog');
    return _itemsOf(
      response,
      'Der globale Modellkatalog ist ungültig.',
    ).map(_mapper.fromJson).toList(growable: false);
  }

  @override
  Future<void> cacheGlobalEntry(String modelId) async {
    await _client.post(
      '/v1/ml-models/catalog/${Uri.encodeComponent(modelId)}/cache',
      {},
    );
  }

  @override
  Stream<List<ModelCacheStatus>> watchCacheStatuses() {
    return watchWorkspaceChannel('model-cache', _loadCacheStatuses, _channel);
  }

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() {
    return watchWorkspaceChannel('model-catalog', _load, _channel);
  }

  Future<List<ModelCatalogEntry>> _load() async {
    final response = await _client.get('/v1/ml-models');
    return _itemsOf(
      response,
      'Der Modellkatalog ist ungültig.',
    ).map(_mapper.fromJson).toList(growable: false);
  }

  Future<List<ModelCacheStatus>> _loadCacheStatuses() async {
    final response = await _client.get('/v1/ml-models/cache-status');
    return _itemsOf(
      response,
      'Der Modell-Cache-Status ist ungültig.',
    ).map(_cacheStatusFrom).toList(growable: false);
  }

  ModelCacheStatus _cacheStatusFrom(Object? value) {
    if (value is! Map ||
        value['modelId'] is! String ||
        !const {'downloading', 'failed'}.contains(value['state'])) {
      throw const FormatException('Der Modell-Cache-Status ist ungültig.');
    }
    return ModelCacheStatus(
      modelId: value['modelId'] as String,
      state: value['state'] == 'failed'
          ? ModelCacheState.failed
          : ModelCacheState.downloading,
      message: value['message'] as String?,
    );
  }

  List<Object?> _itemsOf(Map<String, Object?> response, String error) {
    final items = response['items'];
    if (items is! List) throw FormatException(error);
    return items;
  }

  String _importIdFrom(Map<String, Object?> value) {
    final importId = value['importId'];
    if (importId is String && importId.isNotEmpty) return importId;
    throw const FormatException('Die Runtime lieferte keine Import-ID.');
  }

  Map<String, Object?> _manifestFrom(String value) {
    final decoded = jsonDecode(value);
    if (decoded is! Map) {
      throw const FormatException('Das Manifest ist kein JSON-Objekt.');
    }
    return {
      for (final entry in decoded.entries) entry.key.toString(): entry.value,
    };
  }
}
