import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_activity.dart';
import '../../domain/entities/task_run.dart';
import 'activity_tab_content.dart';
import 'activity_tile.dart';
import 'task_activity_detail_page.dart';

class TaskActivityHistory extends StatelessWidget {
  const TaskActivityHistory({
    super.key,
    required this.activities,
    required this.onRefresh,
    this.runs = const [],
  });

  final List<TaskActivity> activities;

  /// Die bekannten Läufe; damit führt ein Durchlauf zu seiner Ergebnisansicht.
  final List<TaskRun> runs;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final taskActivities = _taskActivities;
    if (taskActivities.isEmpty) {
      return const ActivityEmptyState(text: 'Noch keine Aufgaben ausgeführt.');
    }
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: taskActivities.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final activity = taskActivities[index];
          return ActivityTile(
            key: ValueKey(activity.id.value),
            activity: activity,
            onTap: () => _openDetails(context, activity),
          );
        },
      ),
    );
  }

  List<TaskActivity> get _taskActivities {
    return activities
        .where((activity) => activity.target == TaskActivityTarget.task)
        .toList(growable: false);
  }

  void _openDetails(BuildContext context, TaskActivity taskActivity) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TaskActivityDetailPage(
          taskActivity: taskActivity,
          nodeActivities: _nodeActivitiesFor(taskActivity),
          run: runs.where((run) => run.id == taskActivity.runId).firstOrNull,
        ),
      ),
    );
  }

  List<TaskActivity> _nodeActivitiesFor(TaskActivity taskActivity) {
    final nodeActivities = activities.where((activity) {
      return activity.target == TaskActivityTarget.node &&
          activity.runId.value == taskActivity.runId.value;
    }).toList();
    nodeActivities.sort((first, second) {
      return first.occurredAt.compareTo(second.occurredAt);
    });
    return nodeActivities;
  }
}
