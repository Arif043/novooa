import 'dart:convert';

import 'package:syscat2/core/network/local_runtime_api_client.dart';

import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/repositories/model_catalog_repository.dart';

class LocalModelCatalogRepository implements ModelCatalogRepository {
  const LocalModelCatalogRepository(this._client);

  final LocalRuntimeApiClient _client;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    final manifest = _manifestFrom(value.manifestJson);
    await _client.post('/v1/ml-models', {
      'manifest': manifest,
      'artifactBase64': base64Encode(value.artifactBytes),
    });
  }

  @override
  Future<void> removeEntry(String modelId) {
    return _client.delete('/v1/ml-models/${Uri.encodeComponent(modelId)}');
  }

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() {
    return pollLocalRuntime(_load);
  }

  Future<List<ModelCatalogEntry>> _load() async {
    final response = await _client.get('/v1/ml-models');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Der Modellkatalog ist ungültig.');
    }
    return items.map(_entryFrom).toList(growable: false);
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

  ModelCatalogEntry _entryFrom(Object? value) {
    if (value is! Map) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    final entry = {
      for (final item in value.entries) item.key.toString(): item.value,
    };
    final contract = _object(entry['contract']);
    final artifact = _object(entry['artifactReference']);
    return ModelCatalogEntry(
      id: _text(entry, 'id'),
      title: _text(entry, 'title'),
      description: _text(entry, 'description'),
      tags: _strings(entry['tags']),
      inputCount: _items(contract['inputs']).length,
      outputCount: _items(contract['outputs']).length,
      sizeBytes: _positiveInt(artifact['sizeBytes']),
      isManagedLocally: _object(entry['scope'])['type'] == 'team',
    );
  }

  Map<String, Object?> _object(Object? value) {
    if (value is! Map) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    return {
      for (final entry in value.entries) entry.key.toString(): entry.value,
    };
  }

  List<Object?> _items(Object? value) {
    if (value is! List) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    return value;
  }

  List<String> _strings(Object? value) {
    if (value is! List || !value.every((item) => item is String)) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    return value.cast<String>();
  }

  int _positiveInt(Object? value) {
    if (value is int && value > 0) {
      return value;
    }
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }

  String _text(Map<String, Object?> value, String field) {
    final text = value[field];
    if (text is String && text.isNotEmpty) {
      return text;
    }
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }
}
