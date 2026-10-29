import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/ios_context_menu.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../cubits/run_results_cubit.dart';
import '../../cubits/run_results_state.dart';
import '../../localization/run_result_texts.dart';
import 'run_day_groups.dart';
import 'run_list_row.dart';

/// Linke Spalte bzw. ganze Seite auf dem Handy: Titel, Filter und die Läufe
/// nach Tagen.
class ResultsListPanel extends StatelessWidget {
  const ResultsListPanel({
    super.key,
    required this.state,
    required this.selectedRunId,
    required this.onOpen,
    required this.padding,
  });

  final RunResultsReady state;

  /// Hervorgehoben nur in der breiten Ansicht.
  final String? selectedRunId;
  final ValueChanged<TaskRun> onOpen;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final groups = runDayGroups(state.visibleRuns, locale: locale);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: padding.copyWith(bottom: AppSpacing.md),
          sliver: SliverToBoxAdapter(child: _Header(state: state)),
        ),
        if (groups.isEmpty)
          SliverPadding(
            padding: padding.copyWith(top: 0),
            sliver: SliverToBoxAdapter(
              child: Text(LocaleKeys.results_no_match.tr()),
            ),
          ),
        for (final group in groups)
          SliverPadding(
            padding: padding.copyWith(top: 0, bottom: AppSpacing.md),
            sliver: SliverList.list(
              children: [
                _DayLabel(label: group.label),
                for (final run in group.runs)
                  RunListRow(
                    run: run,
                    selected: run.id.value == selectedRunId,
                    onTap: () => onOpen(run),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

const _all = 'all';

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final RunResultsReady state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filter = state.statusFilter;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              LocaleKeys.results_title.tr(),
              style: theme.textTheme.headlineMedium,
            ),
          ),
        ),
        if (filter != null)
          Text(
            RunResultTexts.status(filter),
            style: theme.textTheme.labelLarge,
          ),
        IosContextMenuButton<String>(
          tooltip: LocaleKeys.results_filter_label.tr(),
          icon: Icons.filter_list,
          entries: [
            IosContextMenuItem(
              value: _all,
              icon: Icons.select_all,
              label: LocaleKeys.results_filter_all.tr(),
            ),
            for (final status in TaskRunStatus.values)
              if (state.presentStatuses.contains(status))
                IosContextMenuItem(
                  value: status.name,
                  icon: RunResultTexts.statusIcon(status),
                  label: RunResultTexts.status(status),
                ),
          ],
          // Das Menü meldet kein `null`; „Alle“ ist deshalb ein eigener Wert.
          onSelected: (value) => context.read<RunResultsCubit>().filterByStatus(
            TaskRunStatus.values
                .where((status) => status.name == value)
                .firstOrNull,
          ),
        ),
      ],
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
