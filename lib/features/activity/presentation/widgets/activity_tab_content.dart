import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';
import 'task_run_tile.dart';

class TaskRunList extends StatelessWidget {
  const TaskRunList({super.key, required this.runs, required this.emptyText});

  final List<TaskRun> runs;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) return ActivityEmptyState(text: emptyText);
    return RefreshIndicator(
      onRefresh: context.read<ActivityCubit>().load,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: runs.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) => TaskRunTile(run: runs[index]),
      ),
    );
  }
}

class ActivityEmptyState extends StatelessWidget {
  const ActivityEmptyState({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(text),
      ),
    );
  }
}

class ActivityFailureState extends StatelessWidget {
  const ActivityFailureState({super.key, required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message ?? 'Aktivitäten konnten nicht geladen werden.'),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: context.read<ActivityCubit>().load,
              icon: const Icon(Icons.refresh),
              label: Text('Erneut versuchen', style: textTheme.labelLarge),
            ),
          ],
        ),
      ),
    );
  }
}
