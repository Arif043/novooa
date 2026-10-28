import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../../core/theme/app_spacing.dart';
import '../../../../activity/domain/entities/task_run.dart';
import '../../cubits/run_results_cubit.dart';
import '../../cubits/run_results_state.dart';
import '../../pages/run_result_page.dart';
import 'results_status_filter.dart';
import 'run_result_list_card.dart';

/// Filter und Lauf-Karten als Slivers unter der Kopfzeile.
class ResultsRunList extends StatelessWidget {
  const ResultsRunList({super.key, required this.state, required this.inset});

  final RunResultsReady state;
  final double inset;

  @override
  Widget build(BuildContext context) {
    final runs = state.visibleRuns;
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, AppSpacing.xl),
      sliver: SliverList.list(
        children: [
          ResultsStatusFilter(
            statuses: state.presentStatuses,
            selected: state.statusFilter,
            onSelected: context.read<RunResultsCubit>().filterByStatus,
          ),
          const SizedBox(height: AppSpacing.md),
          if (runs.isEmpty) Text(LocaleKeys.results_no_match.tr()),
          for (final run in runs) ...[
            RunResultListCard(run: run, onTap: () => _open(context, run)),
            const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, TaskRun run) {
    Navigator.of(context).push(RunResultPage.route(run));
  }
}
