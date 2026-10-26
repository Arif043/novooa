import 'package:equatable/equatable.dart';

import 'model_tag.dart';

export 'model_tag.dart';

/// Das Tag-Vokabular: eine Ebene Fachthemen mit optionalen Untertags. Schlüssel, die es nicht
/// kennt (ältere Einträge mit Freitext-Tags), bleiben als Text erhalten.
class ModelTagVocabulary extends Equatable {
  const ModelTagVocabulary(this.tags);

  static const empty = ModelTagVocabulary([]);

  final List<ModelTag> tags;

  /// Bezeichnung in der Sprache: exakter Code, dann reine Sprache, dann Englisch, sonst der Schlüssel.
  String labelFor(String key, String languageTag) {
    final labels = _tag(key)?.labels;
    if (labels == null) return key;
    final normalized = languageTag.replaceAll('_', '-');
    return labels[normalized] ??
        labels[normalized.split('-').first] ??
        labels['en'] ??
        key;
  }

  /// Die Themen der Tags für die Filter-Chips: je Tag sein Obertag oder er selbst. Unbekannte
  /// Schlüssel zählen nicht, damit Freitext-Tags älterer Einträge keine Chips erzeugen.
  Set<String> topicsOf(List<String> keys) => {
    for (final key in keys)
      if (_tag(key) case final tag?) tag.parent ?? tag.key,
  };

  List<String> withAncestors(List<String> keys) => {
    ...keys,
    for (final key in keys) ?_tag(key)?.parent,
  }.toList(growable: false);

  /// Schlüssel, Bezeichnungen und Synonyme aller Sprachen samt Obertags — für die Textsuche.
  Iterable<String> searchTextsFor(List<String> keys) sync* {
    for (final key in withAncestors(keys)) {
      yield key;
      final tag = _tag(key);
      if (tag == null) continue;
      yield* tag.labels.values;
      for (final words in tag.synonyms.values) {
        yield* words;
      }
    }
  }

  // Linear statt Map, damit das Vokabular const bleibt; es umfasst nur wenige Dutzend Tags.
  ModelTag? _tag(String key) => tags.where((tag) => tag.key == key).firstOrNull;

  @override
  List<Object?> get props => [tags];
}
