import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_run.dart';
import '../cubits/activity_cubit.dart';
import 'activity_tab_content.dart';
import 'task_run_interaction_dialog.dart';

class ApprovalRunGrid extends StatelessWidget {
  const ApprovalRunGrid({
    super.key,
    required this.runs,
    required this.emptyText,
  });

  final List<TaskRun> runs;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    if (runs.isEmpty) return ActivityEmptyState(text: emptyText);
    return RefreshIndicator(
      onRefresh: context.read<ActivityCubit>().load,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GridView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: runs.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _columnCountFor(constraints.maxWidth),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.6,
            ),
            itemBuilder: (context, index) => _ApprovalRunTile(run: runs[index]),
          );
        },
      ),
    );
  }

  int _columnCountFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }
}

class _ApprovalRunTile extends StatelessWidget {
  const _ApprovalRunTile({required this.run});

  final TaskRun run;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.md),
        onTap: () => TaskRunInteractionDialog.show(context, run),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.pending_actions_outlined, color: colorScheme.primary),
              const SizedBox(height: AppSpacing.md),
              Text(
                run.taskTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleMedium,
              ),
              const Spacer(),
              Text(_subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  String get _subtitle {
    final nodeId = run.waitingNodeId;
    if (nodeId == null || nodeId.trim().isEmpty) {
      return run.requiresDialogInput || run.requiresMediaInput
          ? 'Wartet auf Eingabe'
          : 'Wartet auf Freigabe';
    }
    return 'Baustein: $nodeId';
  }
}
