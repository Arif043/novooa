import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/logging/syscat_log.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/scroll_boundary_fade.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderBody extends StatefulWidget {
  const TaskBuilderBody({super.key, required this.state});

  final TaskBuilderState state;

  @override
  State<TaskBuilderBody> createState() => _TaskBuilderBodyState();
}

class _TaskBuilderBodyState extends State<TaskBuilderBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      children: [
        FilledButton.icon(
          onPressed: () => _executeTask(cubit),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Aufgabe starten'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Toolbar(),
        const SizedBox(height: AppSpacing.xl),
        if (widget.state case TaskBuilderLoaded(:final editingTask))
          Expanded(
            child: ScrollBoundaryFade(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.only(
                    left: AppSpacing.xxl,
                    right: AppSpacing.xxl,
                    bottom: AppSpacing.xxl,
                  ),
                  child: NodeGraph(nodes: editingTask.nodes),
                ),
              ),
            ),
          ),
          // SizedBox(height: AppSpacing.xxl)
      ],
    );
  }

  Future<void> _executeTask(TaskBuilderCubit cubit) async {
    final task = cubit.loadedTaskOrNull();
    if (task == null) return;
    logSyscatInfo(
      'Run-Button startet Aufgabe: ${task.id}',
      name: 'syscat.task_builder',
    );
    final taskRunOrFailure = await serviceLocator<ExecuteTask>()(
      ExecuteTaskParams(task: task),
    );
    taskRunOrFailure.when(
      (run) => _logRunStarted(run.runId.value),
      (failure) => _logRunFailed(failure.message),
    );
  }

  void _logRunStarted(String runId) {
    logSyscatInfo(
      'Run-Button: Aufgabe im Hintergrund gestartet: $runId',
      name: 'syscat.task_builder',
    );
  }

  void _logRunFailed(String message) {
    logSyscatInfo(
      'Run-Button: Aufgabe fehlgeschlagen: $message',
      name: 'syscat.task_builder',
    );
  }
}
