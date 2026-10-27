import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../machine_learning/presentation/widgets/model_language_label.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import 'model_search_selection.dart';

/// Eine wählbare Option der Filter samt Trefferzahl; [onToggle] wählt sie an oder ab.
class ModelFilterOption {
  const ModelFilterOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onToggle,
    this.icon,
  });

  final String label;
  final IconData? icon;
  final int count;
  final bool selected;
  final VoidCallback onToggle;
}

/// Eine Filtergruppe; Mehrfachauswahl gibt es nur bei Sprachen.
class ModelFilterSection {
  const ModelFilterSection({
    required this.title,
    required this.options,
    this.multiSelect = false,
  });

  final String title;
  final List<ModelFilterOption> options;
  final bool multiSelect;

  Iterable<ModelFilterOption> get selectedOptions =>
      options.where((option) => option.selected);
}

/// Leitet aus Trefferzahlen und Auswahl die Filtergruppen ab. Eine Gruppe erscheint nur mit mehr
/// als einer Option oder einer Auswahl; bei vielen Aufgaben steht davor eine Bereichsebene.
class ModelFilterSectionsBuilder {
  const ModelFilterSectionsBuilder({
    required this.facets,
    required this.selection,
    required this.showTasks,
    required this.topicLabel,
    required this.onChanged,
  });

  /// Ab so vielen Aufgaben hilft die vorgeschaltete Bereichsebene beim Überblick.
  static const areaThreshold = 6;

  final ModelSearchFacets facets;
  final ModelSearchSelection selection;

  /// Bausteine mit fester Aufgabe blenden Bereich und Aufgabe aus.
  final bool showTasks;

  /// Bezeichnung eines Themas (Obertag) in der Sprache der Oberfläche.
  final String Function(String topic) topicLabel;
  final ValueChanged<ModelSearchSelection> onChanged;

  List<ModelFilterSection> build() => [
    if (_showsAreas) _areas(),
    if (showTasks) _tasks(),
    _topics(),
    _languages(),
  ].where(_isUseful).toList(growable: false);

  bool get _showsAreas =>
      showTasks &&
      _visible(facets.areas, {?selection.area}).length > 1 &&
      (selection.area != null || facets.tasks.length > areaThreshold);

  bool _isUseful(ModelFilterSection section) =>
      section.options.length > 1 || section.selectedOptions.isNotEmpty;

  ModelFilterSection _areas() => ModelFilterSection(
    title: LocaleKeys.ui_bereich.tr(),
    options: [
      for (final area in _visible(facets.areas, {?selection.area}))
        ModelFilterOption(
          icon: area.icon,
          label: area.label,
          count: facets.areas[area] ?? 0,
          selected: selection.area == area,
          onToggle: () => onChanged(selection.toggleArea(area)),
        ),
    ],
  );

  ModelFilterSection _tasks() => ModelFilterSection(
    title: LocaleKeys.ui_aufgabe.tr(),
    options: [
      for (final task in _visible(facets.tasks, {?selection.task}))
        ModelFilterOption(
          icon: task.icon,
          label: task.label,
          count: facets.tasks[task] ?? 0,
          selected: selection.task == task,
          onToggle: () => onChanged(selection.toggleTask(task)),
        ),
    ],
  );

  ModelFilterSection _topics() => ModelFilterSection(
    title: LocaleKeys.ui_themen.tr(),
    options: [
      for (final topic in _visible(facets.topics, {?selection.topic}))
        ModelFilterOption(
          label: topicLabel(topic),
          count: facets.topics[topic] ?? 0,
          selected: selection.topic == topic,
          onToggle: () => onChanged(selection.toggleTopic(topic)),
        ),
    ],
  );

  ModelFilterSection _languages() => ModelFilterSection(
    title: LocaleKeys.ui_sprache.tr(),
    multiSelect: true,
    options: [
      for (final language in _visible(facets.languages, selection.languages))
        ModelFilterOption(
          label: languageLabel(language),
          count: facets.languages[language] ?? 0,
          selected: selection.languages.contains(language),
          onToggle: () => onChanged(selection.toggleLanguage(language)),
        ),
    ],
  );

  /// Nach Treffern absteigend; gewählte Optionen bleiben sichtbar, auch ohne Treffer.
  List<T> _visible<T>(Map<T, int> counts, Set<T> selected) {
    final keys = {...counts.keys, ...selected}.toList();
    keys.sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    return keys;
  }
}
