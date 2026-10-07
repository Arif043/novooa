import '../../../../machine_learning/domain/entities/model_task.dart';

/// Gewählte Filter-Chips: höchstens eine Aufgabe, beliebig viele Sprachen.
class ModelSearchSelection {
  const ModelSearchSelection({this.task, this.languages = const {}});

  final ModelTask? task;
  final Set<String> languages;

  bool get isActive => task != null || languages.isNotEmpty;

  /// Erneutes Tippen auf die gewählte Aufgabe hebt die Auswahl auf.
  ModelSearchSelection toggleTask(ModelTask value) => ModelSearchSelection(
    task: task == value ? null : value,
    languages: languages,
  );

  ModelSearchSelection toggleLanguage(String value) => ModelSearchSelection(
    task: task,
    languages: languages.contains(value)
        ? ({...languages}..remove(value))
        : {...languages, value},
  );
}

/// Trefferzahlen je Chip — jeweils unter Berücksichtigung der anderen Filtergruppe.
class ModelSearchFacets {
  const ModelSearchFacets({required this.tasks, required this.languages});

  final Map<ModelTask, int> tasks;
  final Map<String, int> languages;
}
