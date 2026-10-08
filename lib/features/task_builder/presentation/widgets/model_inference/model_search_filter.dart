import '../../../../machine_learning/domain/entities/model_catalog_entry.dart';
import '../../../../machine_learning/presentation/widgets/model_language_label.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import 'model_search_selection.dart';

enum SpeechModelDirection { textToSpeech, speechToText }

/// Welche Modelle ein Baustein anbietet und welche zu Suche und Filter-Chips passen.
/// Bereich, Aufgabe und Sprache werden UND-verknüpft, mehrere Sprachen untereinander ODER.
class ModelSearchFilter {
  const ModelSearchFilter({required this.languageTag, this.speechDirection});

  final String languageTag;
  final SpeechModelDirection? speechDirection;

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
      .where((model) => _hasLanguage(model, selection))
      .toList(growable: false);

  ModelSearchFacets facets(
    List<ModelCatalogEntry> models,
    String query,
    ModelSearchSelection selection,
  ) {
    final candidates = _candidates(models, query);
    final ofLanguage = candidates.where(
      (model) => _hasLanguage(model, selection),
    );
    return ModelSearchFacets(
      areas: _count(ofLanguage, (model) => [model.task.area]),
      tasks: _count(
        ofLanguage.where((model) => _hasArea(model, selection)),
        (model) => [model.task],
      ),
      languages: _count(
        candidates
            .where((model) => _hasArea(model, selection))
            .where((model) => _hasTask(model, selection)),
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

  bool _hasArea(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.area == null || model.task.area == selection.area;

  bool _hasTask(ModelCatalogEntry model, ModelSearchSelection selection) =>
      selection.task == null || model.task == selection.task;

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
      ...model.tagsFor(languageTag),
      // Aufgabe und Sprachen sind keine Tags mehr, sollen aber per Text auffindbar bleiben.
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
