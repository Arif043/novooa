import 'package:flutter/material.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../machine_learning/presentation/widgets/model_task_label.dart';
import 'model_search_selection.dart';

/// Chips zum Eingrenzen der Modellsuche nach Aufgabe (eine) und Sprache (mehrere).
/// Gezeigt werden nur Chips mit Treffern; eine Zeile mit nur einer Option entfällt.
class ModelFilterChips extends StatelessWidget {
  const ModelFilterChips({
    super.key,
    required this.facets,
    required this.selection,
    required this.showTasks,
    required this.onChanged,
  });

  final ModelSearchFacets facets;
  final ModelSearchSelection selection;
  final bool showTasks;
  final ValueChanged<ModelSearchSelection> onChanged;

  @override
  Widget build(BuildContext context) {
    final tasks = _visible(facets.tasks, {?selection.task});
    final languages = _visible(facets.languages, selection.languages);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTasks && tasks.length > 1)
          _ChipRow(
            label: 'Aufgabe',
            chips: [
              for (final task in tasks)
                FilterChip(
                  avatar: Icon(task.icon),
                  label: Text('${task.label} ${facets.tasks[task] ?? 0}'),
                  selected: selection.task == task,
                  showCheckmark: false,
                  onSelected: (_) => onChanged(selection.toggleTask(task)),
                ),
            ],
          ),
        if (languages.length > 1)
          _ChipRow(
            label: 'Sprache',
            chips: [
              for (final language in languages)
                FilterChip(
                  label: Text(
                    '${languageLabel(language)} '
                    '${facets.languages[language] ?? 0}',
                  ),
                  selected: selection.languages.contains(language),
                  onSelected: (_) =>
                      onChanged(selection.toggleLanguage(language)),
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

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.label, required this.chips});

  final String label;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label: '$label filtern',
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
