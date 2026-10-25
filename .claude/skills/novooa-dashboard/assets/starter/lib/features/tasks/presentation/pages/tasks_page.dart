import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/dashboard_theme.dart';
import '../../../../l10n/dashboard_keys.dart';
import '../../../../shared/async_views.dart';
import '../../domain/entities/dashboard_task.dart';
import '../cubits/task_start_cubit.dart';
import '../cubits/tasks_cubit.dart';
import '../cubits/tasks_state.dart';
import '../widgets/task_card.dart';

/// Aufgaben starten: Liste mit „Starten“, Rückmeldung als Snackbar.
class TasksPage extends StatelessWidget {
  const TasksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<TaskStartCubit, TaskStartState>(
      listener: _announce,
      child: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) => switch (state) {
          TasksLoading() => const LoadingView(),
          TasksFailure() => FailureView(
            message: DashboardKeys.loadFailed.tr(),
            onRetry: context.read<TasksCubit>().load,
          ),
          TasksLoaded(:final tasks) when tasks.isEmpty => EmptyView(
            message: DashboardKeys.tasksEmpty.tr(),
          ),
          TasksLoaded(:final tasks) => _TaskList(tasks: tasks),
        },
      ),
    );
  }

  void _announce(BuildContext context, TaskStartState state) {
    final message = switch (state) {
      TaskStarted(:final task) => DashboardKeys.tasksStarted.tr(
        namedArgs: {'title': task.title},
      ),
      TaskStartFailed() => DashboardKeys.tasksStartFailed.tr(),
      _ => null,
    };
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TaskList extends StatelessWidget {
  const _TaskList({required this.tasks});

  final List<DashboardTask> tasks;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.md),
      itemCount: tasks.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.sm),
      itemBuilder: (_, index) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.contentMaxWidth),
          child: TaskCard(task: tasks[index]),
        ),
      ),
    );
  }
}
