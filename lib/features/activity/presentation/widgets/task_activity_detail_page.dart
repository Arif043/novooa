import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import 'activity_tab_content.dart';
import 'activity_tile.dart';

class TaskActivityDetailPage extends StatelessWidget {
  const TaskActivityDetailPage({
    super.key,
    required this.taskActivity,
    required this.nodeActivities,
  });

  final TaskActivity taskActivity;
  final List<TaskActivity> nodeActivities;

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
      appBar: AppBar(title: Text(taskActivity.taskTitle)),
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
