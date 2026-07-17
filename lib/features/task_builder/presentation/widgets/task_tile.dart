import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/task.dart';
import 'task_context_menu.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: () => context.go('/tasks/builder', extra: task),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.account_tree_outlined, color: colorScheme.primary),
                  const Spacer(),
                  TaskContextMenu(task: task),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                task.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const Spacer(),
              Text(
                '${task.nodes.length} Bausteine',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
