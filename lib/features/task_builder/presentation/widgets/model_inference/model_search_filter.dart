import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';

enum SpeechModelDirection { textToSpeech, speechToText }

/// Welche Modelle ein Baustein anbietet und welche zu einer Suche passen.
class ModelSearchFilter {
  const ModelSearchFilter({required this.languageTag, this.speechDirection});

  final String languageTag;
  final SpeechModelDirection? speechDirection;

  List<ModelCatalogEntry> apply(List<ModelCatalogEntry> models, String query) {
    final terms = _termsOf(query);
    return models
        .where(suits)
        .where((model) => terms.every((term) => _matches(model, term)))
        .toList(growable: false);
  }

  /// Passt das Modell zum Baustein (Text vorlesen, Audio transkribieren oder beliebig)?
  bool suits(ModelCatalogEntry model) => switch (speechDirection) {
    SpeechModelDirection.textToSpeech =>
      model.inputs.any((input) => input.source == ModelInputSource.text) &&
          model.outputs.any((output) => output.workflowType == 'audio'),
    SpeechModelDirection.speechToText => model.inputs.any(
      (input) => input.source == ModelInputSource.audio,
    ),
    null => true,
  };

  bool _matches(ModelCatalogEntry model, String term) {
    final haystack = [
      model.titleFor(languageTag),
      model.descriptionFor(languageTag),
      ...model.tagsFor(languageTag),
      model.id,
    ].join(' ').toLowerCase();
    return haystack.contains(term);
  }

  List<String> _termsOf(String query) => query
      .toLowerCase()
      .split(RegExp(r'\s+'))
      .where((term) => term.isNotEmpty)
      .toList(growable: false);
}
