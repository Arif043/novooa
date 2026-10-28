import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../results/presentation/pages/run_result_page.dart';
import '../../domain/entities/task_activity.dart';
import '../../domain/entities/task_run.dart';
import 'activity_tab_content.dart';
import 'activity_tile.dart';

class TaskActivityDetailPage extends StatelessWidget {
  const TaskActivityDetailPage({
    super.key,
    required this.taskActivity,
    required this.nodeActivities,
    this.run,
  });

  final TaskActivity taskActivity;
  final List<TaskActivity> nodeActivities;

  /// Der Lauf, falls bekannt; dann führt „Ergebnis ansehen“ zur Ergebnisansicht.
  final TaskRun? run;

  /// Die Bausteine in der Reihenfolge des Plans; ein fehlgeschlagener Baustein steht an seiner Stelle.
  /// Nur wenn ein Lauf scheitert, ohne dass ein Baustein die Ursache war (etwa ein ungültiger Plan),
  /// steht seine Meldung oben als eigener Eintrag.
  List<TaskActivity> get _entries => [
    if (taskActivity.status == TaskActivityStatus.failed && !_hasFailedNode)
      taskActivity,
    ...nodeActivities,
  ];

  bool get _hasFailedNode => nodeActivities.any(
    (activity) => activity.status == TaskActivityStatus.failed,
  );

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(taskActivity.taskTitle),
        actions: [
          if (run case final run?)
            TextButton.icon(
              onPressed: () =>
                  Navigator.of(context).push(RunResultPage.route(run)),
              icon: const Icon(Icons.account_tree_outlined),
              label: Text(LocaleKeys.results_open_result.tr()),
            ),
        ],
      ),
      body: entries.isEmpty
          ? const ActivityEmptyState(
              text:
                  'Für diesen Durchlauf gibt es noch keine Baustein-Aktivitäten.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final activity = entries[index];
                return ActivityTile(
                  key: ValueKey(activity.id.value),
                  activity: activity,
                );
              },
            ),
    );
  }
}
