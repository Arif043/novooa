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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(taskActivity.taskTitle)),
      body: nodeActivities.isEmpty
          ? const ActivityEmptyState(
              text:
                  'Für diesen Durchlauf gibt es noch keine Baustein-Aktivitäten.',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: nodeActivities.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final activity = nodeActivities[index];
                return ActivityTile(
                  key: ValueKey(activity.id.value),
                  activity: activity,
                );
              },
            ),
    );
  }
}
