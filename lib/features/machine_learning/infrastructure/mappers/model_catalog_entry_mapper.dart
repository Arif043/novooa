import '../../domain/entities/model_catalog_entry.dart';
import 'model_json_fields.dart';
import 'model_setting_mapper.dart';

/// Übersetzt Katalogeinträge der Runtime-API (JSON) in Domain-Entitäten.
class ModelCatalogEntryMapper {
  const ModelCatalogEntryMapper();

  ModelCatalogEntry fromJson(Object? value) {
    if (value is! Map) {
      throw const FormatException('Ein Modellkatalogeintrag ist ungültig.');
    }
    final entry = {
      for (final item in value.entries) item.key.toString(): item.value,
    };
    final contract = jsonObject(entry['contract']);
    final artifact = jsonObject(entry['artifactReference']);
    final inputs = jsonItems(
      contract['inputs'],
    ).map(_manifestInputFrom).toList(growable: false);
    final outputs = jsonItems(
      contract['outputs'],
    ).map(_manifestOutputFrom).toList(growable: false);
    final settings = jsonItemsOrEmpty(
      contract['settings'],
    ).map(const ModelSettingMapper().fromJson).toList(growable: false);
    return ModelCatalogEntry(
      id: jsonText(entry, 'id'),
      title: jsonText(entry, 'title'),
      description: jsonText(entry, 'description'),
      translations: _translationsFrom(entry['translations']),
      task: ModelTask.fromKey(entry['task']),
      languages: entry['languages'] == null
          ? const []
          : jsonStrings(entry['languages']),
      tags: jsonStrings(entry['tags']),
      inputs: inputs,
      settings: settings,
      outputs: outputs,
      outputCount: jsonItems(contract['outputs']).length,
      sizeBytes: jsonPositiveInt(artifact['sizeBytes']),
      origin: _originFrom(entry),
    );
  }

  /// Teameinträge liegen lokal vor; ältere Runtimes ohne `origin` kannten nur Importe.
  ModelOrigin? _originFrom(Map<String, Object?> entry) {
    if (jsonObject(entry['scope'])['type'] != 'team') return null;
    return switch (entry['origin']) {
      'catalog' => ModelOrigin.catalog,
      _ => ModelOrigin.import,
    };
  }

  Map<String, ModelTranslation> _translationsFrom(Object? value) {
    if (value == null) return const {};
    return {
      for (final entry in jsonObject(value).entries)
        entry.key: ModelTranslation(
          title: jsonText(jsonObject(entry.value), 'title'),
          description: jsonText(jsonObject(entry.value), 'description'),
          tags: jsonObject(entry.value)['tags'] == null
              ? null
              : jsonStrings(jsonObject(entry.value)['tags']),
        ),
    };
  }

  ModelManifestOutput _manifestOutputFrom(Object? value) {
    final output = jsonObject(value);
    final workflowOutput = _workflowOutputFrom(
      jsonObject(output['workflowOutput']),
    );
    return ModelManifestOutput(
      tensorName: jsonText(output, 'name'),
      workflowName: workflowOutput['name'] as String,
      workflowType: workflowOutput['type'] as String,
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
          'image',
        }.contains(type)) {
      throw const FormatException('Die Workflow-Ausgabe ist ungültig.');
    }
    return {'name': name, 'type': type};
  }

  ModelManifestInput _manifestInputFrom(Object? value) {
    final input = jsonObject(value);
    return ModelManifestInput(
      name: jsonText(input, 'name'),
      source: _sourceFrom(jsonText(input, 'source')),
      dataType: jsonText(input, 'dataType'),
      shape: _shapeFrom(input['shape']),
      requiresWorkflowMapping: _requiresWorkflowMapping(input['binding']),
    );
  }

  bool _requiresWorkflowMapping(Object? value) {
    if (value == null) return true;
    return jsonObject(value)['type'] == 'workflow';
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
}
