import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/domain/entities/model_tag_vocabulary.dart';
import '../../../../machine_learning/presentation/widgets/model_language_label.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import 'model_search_selection.dart';

enum SpeechModelDirection { textToSpeech, speechToText }

/// Welche Modelle ein Baustein anbietet und welche zu Suche und Filter-Chips passen.
/// Bereich, Aufgabe, Thema und Sprache werden UND-verknüpft, mehrere Sprachen untereinander ODER.
class ModelSearchFilter {
  const ModelSearchFilter({
    required this.languageTag,
    this.speechDirection,
    this.vocabulary = ModelTagVocabulary.empty,
  });

  final String languageTag;
  final SpeechModelDirection? speechDirection;

  /// Liefert Bezeichnungen, Synonyme und Obertags der Tags für Suche und Themen-Chips.
  final ModelTagVocabulary vocabulary;

  ModelSearchFilter withVocabulary(ModelTagVocabulary value) =>
      ModelSearchFilter(
        languageTag: languageTag,
        speechDirection: speechDirection,
        vocabulary: value,
      );

  /// Bausteine wie „Text vorlesen“ legen die Aufgabe fest; die Aufgaben-Chips entfallen.
  ModelTask? get fixedTask => switch (speechDirection) {
    SpeechModelDirection.textToSpeech => ModelTask.textToSpeech,
    SpeechModelDirection.speechToText => ModelTask.automaticSpeechRecognition,
    null => null,
  };

  List<ModelCatalogEntry> apply(
    List<ModelCatalogEntry> models,
    String query, [
    ModelSearchSelection selection = const ModelSearchSelection(),
  ]) => _candidates(models, query)
      .where((model) => _hasArea(model, selection))
      .where((model) => _hasTask(model, selection))
      .where((model) => _hasTopic(model, selection))
      .where((model) => _hasLanguage(model, selection))
      .toList(growable: false);

  /// Jede Chip-Reihe zählt unter allen Filtern außer ihrem eigenen (Bereiche auch ohne Aufgabe).
  ModelSearchFacets facets(
    List<ModelCatalogEntry> models,
    String query,
    ModelSearchSelection selection,
  ) {
    final candidates = _candidates(models, query).toList(growable: false);
    bool area(ModelCatalogEntry model) => _hasArea(model, selection);
    bool task(ModelCatalogEntry model) => _hasTask(model, selection);
    bool topic(ModelCatalogEntry model) => _hasTopic(model, selection);
    bool language(ModelCatalogEntry model) => _hasLanguage(model, selection);
    return ModelSearchFacets(
      areas: _count(
        _where(candidates, [language, topic]),
        (model) => [model.task.area],
      ),
      tasks: _count(
        _where(candidates, [area, language, topic]),
        (model) => [model.task],
      ),
      topics: _count(
        _where(candidates, [area, task, language]),
        (model) => vocabulary.topicsOf(model.tags),
      ),
      languages: _count(
        _where(candidates, [area, task, topic]),
        (model) => model.languages,
      ),
    );
  }

  /// Passt das Modell zum Baustein? Alt-Einträge ohne Aufgabe prüft der Vertrag.
  bool suits(ModelCatalogEntry model) {
    final task = fixedTask;
    if (task == null || model.task == task) return true;
    if (model.task != ModelTask.other) return false;
    return switch (task) {
      ModelTask.textToSpeech =>
        model.inputs.any((input) => input.source == ModelInputSource.text) &&
            model.outputs.any((output) => output.workflowType == 'audio'),
      _ => model.inputs.any((input) => input.source == ModelInputSource.audio),
    };
  }

  Iterable<ModelCatalogEntry> _candidates(
    List<ModelCatalogEntry> models,
    String query,
  ) {
    final terms = _termsOf(query);
    return models
        .where(suits)
        .where((model) => terms.every((term) => _matches(model, term)));
  }

  Iterable<ModelCatalogEntry> _where(
    List<ModelCatalogEntry> models,
    List<bool Function(ModelCatalogEntry)> conditions,
  ) => models.where((model) => conditions.every((check) => check(model)));

  bool _hasArea(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.area == null || model.task.area == selection.area;

  bool _hasTask(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.task == null || model.task == selection.task;

  bool _hasTopic(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.topic == null ||
      vocabulary.topicsOf(model.tags).contains(selection.topic);

  bool _hasLanguage(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.languages.isEmpty ||
      model.languages.any(selection.languages.contains);

  Map<T, int> _count<T>(
    Iterable<ModelCatalogEntry> models,
    Iterable<T> Function(ModelCatalogEntry) keysOf,
  ) {
    final counts = <T, int>{};
    for (final key in models.expand(keysOf)) {
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts;
  }

  bool _matches(ModelCatalogEntry model, String term) {
    final haystack = [
      model.titleFor(languageTag),
      model.descriptionFor(languageTag),
      // Tags in allen Sprachen samt Synonymen und Obertags: „Tiere“ findet auch „Haustiere“.
      ...vocabulary.searchTextsFor(model.tags),
      // Aufgabe und Sprachen sind keine Tags, sollen aber per Text auffindbar bleiben.
      model.task.label,
      model.task.area.label,
      ...model.languages.map(languageLabel),
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
