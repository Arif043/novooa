import 'dart:convert';

import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_realtime_channel.dart';

import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/repositories/model_catalog_repository.dart';

class LocalModelCatalogRepository
    implements ModelCatalogRepository, GlobalModelCatalogRepository {
  const LocalModelCatalogRepository(this._client, this._channel);

  final WorkspaceApiClient _client;
  final WorkspaceRealtimeChannel _channel;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    final manifest = _manifestFrom(value.manifestJson);
    final import = await _client.post('/v1/ml-models/imports', {
      'manifest': manifest,
    });
    final importId = _importIdFrom(import);
    await _client.putStream(
      '/v1/ml-models/imports/${Uri.encodeComponent(importId)}/artifact',
      body: value.openArtifact(),
      contentLength: value.artifactLength,
      contentType: 'application/onnx',
      timeout: const Duration(minutes: 10),
    );
  }

  @override
  Future<void> removeEntry(String modelId) {
    return _client.delete('/v1/ml-models/${Uri.encodeComponent(modelId)}');
  }

  @override
  Future<List<ModelCatalogEntry>> loadGlobalEntries() async {
    final response = await _client.get('/v1/ml-models/catalog');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Der globale Modellkatalog ist ungültig.');
    }
    return items.map(_entryFrom).toList(growable: false);
  }

  @override
  Future<void> installGlobalEntry(String modelId) async {
    await _client.post(
      '/v1/ml-models/catalog/${Uri.encodeComponent(modelId)}/install',
      {},
    );
  }

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() {
    return watchWorkspaceChannel('model-catalog', _load, _channel);
  }

  Future<List<ModelCatalogEntry>> _load() async {
    final response = await _client.get('/v1/ml-models');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Der Modellkatalog ist ungültig.');
    }
    return items.map(_entryFrom).toList(growable: false);
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

  ModelCatalogEntry _entryFrom(Object? value) {
    if (value is! Map) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    final entry = {
      for (final item in value.entries) item.key.toString(): item.value,
    };
    final contract = _object(entry['contract']);
    final artifact = _object(entry['artifactReference']);
    final inputs = _items(
      contract['inputs'],
    ).map(_manifestInputFrom).toList(growable: false);
    final outputs = _items(
      contract['outputs'],
    ).map(_manifestOutputFrom).toList(growable: false);
    final settings = _itemsOrEmpty(
      contract['settings'],
    ).map(_manifestSettingFrom).toList(growable: false);
    return ModelCatalogEntry(
      id: _text(entry, 'id'),
      title: _text(entry, 'title'),
      description: _text(entry, 'description'),
      translations: _translationsFrom(entry['translations']),
      tags: _strings(entry['tags']),
      inputs: inputs,
      settings: settings,
      outputs: outputs,
      outputCount: _items(contract['outputs']).length,
      sizeBytes: _positiveInt(artifact['sizeBytes']),
      isManagedLocally: _object(entry['scope'])['type'] == 'team',
    );
  }

  Map<String, ModelTranslation> _translationsFrom(Object? value) {
    if (value == null) return const {};
    return {
      for (final entry in _object(value).entries)
        entry.key: ModelTranslation(
          title: _text(_object(entry.value), 'title'),
          description: _text(_object(entry.value), 'description'),
        ),
    };
  }

  ModelManifestOutput _manifestOutputFrom(Object? value) {
    final output = _object(value);
    final workflowOutput = _workflowOutputFrom(
      _object(output['workflowOutput']),
    );
    return ModelManifestOutput(
      tensorName: _text(output, 'name'),
      workflowName: workflowOutput['name'] as String,
      workflowType: workflowOutput['type'] as String,
      parameters: _outputParametersFrom(output['transformations']),
    );
  }

  Map<String, Object?> _workflowOutputFrom(Map<String, Object?> output) {
    final name = output['name'];
    final type = output['type'];
    if (name is! String ||
        name.isEmpty ||
        type is! String ||
        !const {
          'string',
          'number',
          'boolean',
          'json',
          'audio',
        }.contains(type)) {
      throw const FormatException('Die Workflow-Ausgabe ist ungültig.');
    }
    return {'name': name, 'type': type};
  }

  List<ModelManifestOutputParameter> _outputParametersFrom(Object? value) {
    return _items(value)
        .map(_object)
        .map((item) => _parameterFrom(item['parameters']))
        .whereType<ModelManifestOutputParameter>()
        .toList(growable: false);
  }

  ModelManifestOutputParameter? _parameterFrom(Object? value) {
    if (value is! Map) return null;
    final parameters = _object(value);
    final descriptor = parameters['parameter'];
    if (descriptor is! Map) return null;
    final parameter = _object(descriptor);
    final name = parameter['name'];
    final defaultValue = parameter['default'];
    final minimum = parameter['minimum'];
    final maximum = parameter['maximum'];
    if (name is! String ||
        defaultValue is! int ||
        minimum is! int ||
        maximum is! int ||
        minimum > defaultValue ||
        defaultValue > maximum) {
      throw const FormatException('Der Ausgangsparameter ist ungültig.');
    }
    return ModelManifestOutputParameter(
      name: name,
      label: parameter['label'] as String? ?? name,
      defaultValue: defaultValue,
      minimum: minimum,
      maximum: maximum,
    );
  }

  ModelManifestInput _manifestInputFrom(Object? value) {
    final input = _object(value);
    return ModelManifestInput(
      name: _text(input, 'name'),
      source: _sourceFrom(_text(input, 'source')),
      dataType: _text(input, 'dataType'),
      shape: _shapeFrom(input['shape']),
      requiresWorkflowMapping: _requiresWorkflowMapping(input['binding']),
    );
  }

  bool _requiresWorkflowMapping(Object? value) {
    if (value == null) return true;
    return _object(value)['type'] == 'workflow';
  }

  ModelManifestSetting _manifestSettingFrom(Object? value) {
    final parameter = _object(value);
    return ModelManifestSetting(
      name: _text(parameter, 'name'),
      label: _text(parameter, 'label'),
      control: _settingControlFrom(parameter['control']),
    );
  }

  ModelManifestSettingControl _settingControlFrom(Object? value) {
    final control = _object(value);
    return switch (_text(control, 'type')) {
      'slider' => ModelManifestSliderControl(
        initial: _number(control['initial']),
        minimum: _number(control['minimum']),
        maximum: _number(control['maximum']),
        step: _number(control['step']),
      ),
      'checkbox' => ModelManifestCheckboxControl(
        initial: _boolean(control['initial']),
      ),
      'radioGroup' => ModelManifestRadioGroupControl(
        initial: _parameterValue(control['initial']),
        options: _items(
          control['options'],
        ).map(_radioOptionFrom).toList(growable: false),
      ),
      _ => throw const FormatException('Der Modellparameter ist ungültig.'),
    };
  }

  ModelManifestSettingOption _radioOptionFrom(Object? value) {
    final option = _object(value);
    return ModelManifestSettingOption(
      value: _parameterValue(option['value']),
      label: _text(option, 'label'),
    );
  }

  Object _parameterValue(Object? value) {
    if (value is String || value is bool || value is num) {
      return value as Object;
    }
    throw const FormatException('Der Modellparameter ist ungültig.');
  }

  List<Object> _shapeFrom(Object? value) {
    if (value is! List ||
        !value.every((dimension) => dimension is int || dimension is String)) {
      throw const FormatException('Der Modelleingang ist ungültig.');
    }
    return value.cast<Object>();
  }

  ModelInputSource _sourceFrom(String value) {
    return ModelInputSource.values.firstWhere(
      (source) => source.name == value,
      orElse: () =>
          throw const FormatException('Der Modelleingang ist ungültig.'),
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

  List<Object?> _itemsOrEmpty(Object? value) {
    if (value == null) return const [];
    return _items(value);
  }

  List<String> _strings(Object? value) {
    if (value is! List || !value.every((item) => item is String)) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    return value.cast<String>();
  }

  int _positiveInt(Object? value) {
    if (value is int && value > 0) return value;
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }

  double _number(Object? value) {
    if (value is num && value.isFinite) return value.toDouble();
    throw const FormatException('Der Modellparameter ist ungültig.');
  }

  bool _boolean(Object? value) {
    if (value is bool) return value;
    throw const FormatException('Der Modellparameter ist ungültig.');
  }

  String _text(Map<String, Object?> value, String field) {
    final text = value[field];
    if (text is String && text.isNotEmpty) return text;
    throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
  }
}
