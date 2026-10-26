import '../../../../machine_learning/domain/entities/model_task.dart';

/// Gewählte Filter-Chips: höchstens ein Bereich, eine Aufgabe und ein Thema, beliebig viele Sprachen.
class ModelSearchSelection {
  const ModelSearchSelection({
    this.area,
    this.task,
    this.topic,
    this.languages = const {},
  });

  final ModelTaskArea? area;
  final ModelTask? task;

  /// Schlüssel eines Obertags aus dem Tag-Vokabular.
  final String? topic;
  final Set<String> languages;

  bool get isActive =>
      area != null || task != null || topic != null || languages.isNotEmpty;

  /// Ein Bereichswechsel verwirft eine Aufgabe, die nicht mehr dazugehört.
  ModelSearchSelection toggleArea(ModelTaskArea value) {
    final nextArea = area == value ? null : value;
    final keepsTask = nextArea == null || task?.area == nextArea;
    return ModelSearchSelection(
      area: nextArea,
      task: keepsTask ? task : null,
      topic: topic,
      languages: languages,
    );
  }

  /// Erneutes Tippen auf die gewählte Aufgabe hebt die Auswahl auf.
  ModelSearchSelection toggleTask(ModelTask value) => ModelSearchSelection(
    area: area,
    task: task == value ? null : value,
    topic: topic,
    languages: languages,
  );

  /// Erneutes Tippen auf das gewählte Thema hebt die Auswahl auf.
  ModelSearchSelection toggleTopic(String value) => ModelSearchSelection(
    area: area,
    task: task,
    topic: topic == value ? null : value,
    languages: languages,
  );

  ModelSearchSelection toggleLanguage(String value) => ModelSearchSelection(
    area: area,
    task: task,
    topic: topic,
    languages: languages.contains(value)
        ? ({...languages}..remove(value))
        : {...languages, value},
  );
}

/// Trefferzahlen je Chip — jeweils unter Berücksichtigung der übrigen Filter.
class ModelSearchFacets {
  const ModelSearchFacets({
    this.areas = const {},
    required this.tasks,
    this.topics = const {},
    required this.languages,
  });

  final Map<ModelTaskArea, int> areas;
  final Map<ModelTask, int> tasks;
  final Map<String, int> topics;
  final Map<String, int> languages;
}
