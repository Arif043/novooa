import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/presentation/widgets/model_language_label.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import 'model_search_selection.dart';

/// Chips zum Eingrenzen der Modellsuche nach Bereich, Aufgabe, Thema (je eins) und Sprache (mehrere).
/// Gezeigt werden nur Chips mit Treffern; eine Zeile mit nur einer Option entfällt. Bei vielen
/// Aufgaben erscheint davor eine Bereichsebene (Bild & Video, Audio, Text …).
class ModelFilterChips extends StatelessWidget {
  const ModelFilterChips({
    super.key,
    required this.facets,
    required this.selection,
    required this.showTasks,
    required this.topicLabel,
    required this.onChanged,
  });

  final ModelSearchFacets facets;
  final ModelSearchSelection selection;
  final bool showTasks;

  /// Bezeichnung eines Themas (Obertag) in der Sprache der Oberfläche.
  final String Function(String topic) topicLabel;
  final ValueChanged<ModelSearchSelection> onChanged;

  /// Ab so vielen Aufgaben-Chips hilft die vorgeschaltete Bereichsebene beim Überblick.
  static const areaThreshold = 6;

  @override
  Widget build(BuildContext context) {
    final areas = _visible(facets.areas, {?selection.area});
    final tasks = _visible(facets.tasks, {?selection.task});
    final topics = _visible(facets.topics, {?selection.topic});
    final languages = _visible(facets.languages, selection.languages);
    final showAreas =
        showTasks &&
        areas.length > 1 &&
        (selection.area != null || facets.tasks.length > areaThreshold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showAreas)
          _ChipRow(
            label: LocaleKeys.ui_bereich.tr(),
            chips: [
              for (final area in areas)
                _CountChip(
                  icon: area.icon,
                  label: area.label,
                  count: facets.areas[area] ?? 0,
                  selected: selection.area == area,
                  onTap: () => onChanged(selection.toggleArea(area)),
                ),
            ],
          ),
        if (showTasks && (tasks.length > 1 || selection.area != null))
          _ChipRow(
            label: LocaleKeys.ui_aufgabe.tr(),
            chips: [
              for (final task in tasks)
                _CountChip(
                  icon: task.icon,
                  label: task.label,
                  count: facets.tasks[task] ?? 0,
                  selected: selection.task == task,
                  onTap: () => onChanged(selection.toggleTask(task)),
                ),
            ],
          ),
        if (topics.length > 1 || selection.topic != null)
          _ChipRow(
            label: LocaleKeys.ui_themen.tr(),
            chips: [
              for (final topic in topics)
                _CountChip(
                  label: topicLabel(topic),
                  count: facets.topics[topic] ?? 0,
                  selected: selection.topic == topic,
                  onTap: () => onChanged(selection.toggleTopic(topic)),
                ),
            ],
          ),
        if (languages.length > 1)
          _ChipRow(
            label: LocaleKeys.ui_sprache.tr(),
            chips: [
              for (final language in languages)
                _CountChip(
                  label: languageLabel(language),
                  count: facets.languages[language] ?? 0,
                  selected: selection.languages.contains(language),
                  onTap: () => onChanged(selection.toggleLanguage(language)),
                ),
            ],
          ),
      ],
    );
  }

  /// Nach Treffern absteigend; gewählte Optionen bleiben sichtbar, auch ohne Treffer.
  List<T> _visible<T>(Map<T, int> counts, Set<T> selected) {
    final keys = {...counts.keys, ...selected}.toList();
    keys.sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));
    return keys;
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final IconData? icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon == null ? null : Icon(icon),
      label: Text('$label $count'),
      selected: selected,
      showCheckmark: icon == null,
      onSelected: (_) => onTap(),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.chips});

  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: LocaleKeys.ui_filter_by_label.tr(namedArgs: {'label': label}),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              for (final chip in chips) ...[
                const SizedBox(width: AppSpacing.sm),
                chip,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
