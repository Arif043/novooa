import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_trigger.dart';
import '../cubits/schedule_cubit.dart';
import 'task_trigger_tile.dart';

class TaskTriggerGrid extends StatelessWidget {
  const TaskTriggerGrid({
    super.key,
    required this.triggers,
    required this.cubit,
  });

  final List<TaskTrigger> triggers;
  final ScheduleCubit cubit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.builder(
          itemCount: triggers.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _columnCountFor(constraints.maxWidth),
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            return TaskTriggerTile(trigger: triggers[index], cubit: cubit);
          },
        );
      },
    );
  }

  int _columnCountFor(double width) {
    if (width >= 1100) return 4;
    if (width >= 760) return 3;
    if (width >= 520) return 2;
    return 1;
  }
}
