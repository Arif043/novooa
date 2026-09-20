import 'package:flutter/material.dart';
import '../../domain/entities/task_trigger.dart';
import '../cubits/schedule_cubit.dart';
import 'task_trigger_tile.dart';

class TaskTriggerList extends StatelessWidget {
  const TaskTriggerList({
    super.key,
    required this.triggers,
    required this.cubit,
  });
  final List<TaskTrigger> triggers;
  final ScheduleCubit cubit;

  @override
  Widget build(BuildContext context) => SliverList.separated(
    itemCount: triggers.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (context, index) => TaskTriggerTile(
      key: ValueKey(triggers[index].id),
      trigger: triggers[index],
      cubit: cubit,
    ),
  );
}
