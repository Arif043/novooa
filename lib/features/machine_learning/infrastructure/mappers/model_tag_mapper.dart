import '../../domain/entities/model_tag_vocabulary.dart';
import 'model_json_fields.dart';

/// Übersetzt das Tag-Vokabular der Runtime-API (`GET /v1/ml-models/tags`) in Domain-Entitäten.
class ModelTagMapper {
  const ModelTagMapper();

  ModelTagVocabulary vocabularyFrom(List<Object?> items) =>
      ModelTagVocabulary(items.map(tagFrom).toList(growable: false));

  ModelTag tagFrom(Object? value) {
    final tag = jsonObject(value);
    final parent = tag['parent'];
    return ModelTag(
      key: jsonText(tag, 'key'),
      parent: parent is String && parent.isNotEmpty ? parent : null,
      labels: _labelsFrom(tag['labels']),
      synonyms: _synonymsFrom(tag['synonyms']),
    );
  }

  Map<String, String> _labelsFrom(Object? value) => {
    for (final entry in jsonObject(value).entries)
      entry.key: jsonText({'label': entry.value}, 'label'),
  };

  Map<String, List<String>> _synonymsFrom(Object? value) {
    if (value == null) return const {};
    return {
      for (final entry in jsonObject(value).entries)
        entry.key: jsonStrings(entry.value),
    };
  }
}
