import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../../../shared/async_views.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/runs_cubit.dart';
import '../widgets/run_card.dart';

/// Läufe live: Status, Ergebnis und offene Freigaben.
class RunsPage extends StatelessWidget {
  const RunsPage({super.key, required this.onShowTasks});

  /// Leerzustand: führt zu den Aufgaben.
  final VoidCallback onShowTasks;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RunsCubit, RunsState>(
      builder: (context, state) => switch (state) {
        RunsLoading() => const LoadingView(),
        RunsFailure() => FailureView(
          message: DashboardKeys.loadFailed.tr(),
          onRetry: context.read<RunsCubit>().load,
        ),
        RunsLoaded(:final runs) when runs.isEmpty => EmptyView(
          message: DashboardKeys.runsEmpty.tr(),
          actionLabel: DashboardKeys.runsShowTasks.tr(),
          onAction: onShowTasks,
        ),
        RunsLoaded(:final runs) => _RunList(runs: runs),
      },
    );
  }
}

class _RunList extends StatelessWidget {
  const _RunList({required this.runs});

  final List<TaskRun> runs;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: runs.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (_, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.contentMaxWidth),
          child: RunCard(run: runs[index]),
        ),
      ),
    );
  }
}
