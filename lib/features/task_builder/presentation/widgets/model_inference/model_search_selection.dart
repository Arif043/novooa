import '../../../../machine_learning/domain/entities/model_task.dart';

/// Gewählte Filter-Chips: höchstens ein Bereich, höchstens eine Aufgabe, beliebig viele Sprachen.
class ModelSearchSelection {
  const ModelSearchSelection({this.area, this.task, this.languages = const {}});

  final ModelTaskArea? area;
  final ModelTask? task;
  final Set<String> languages;

  bool get isActive => area != null || task != null || languages.isNotEmpty;

  /// Ein Bereichswechsel verwirft eine Aufgabe, die nicht mehr dazugehört.
  ModelSearchSelection toggleArea(ModelTaskArea value) {
    final nextArea = area == value ? null : value;
    final keepsTask = nextArea == null || task?.area == nextArea;
    return ModelSearchSelection(
      area: nextArea,
      task: keepsTask ? task : null,
      languages: languages,
    );
  }

  /// Erneutes Tippen auf die gewählte Aufgabe hebt die Auswahl auf.
  ModelSearchSelection toggleTask(ModelTask value) => ModelSearchSelection(
    area: area,
    task: task == value ? null : value,
    languages: languages,
  );

  ModelSearchSelection toggleLanguage(String value) => ModelSearchSelection(
    area: area,
    task: task,
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
    required this.languages,
  });

  final Map<ModelTaskArea, int> areas;
  final Map<ModelTask, int> tasks;
  final Map<String, int> languages;
}
