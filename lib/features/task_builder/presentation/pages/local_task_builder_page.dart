import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/task_title_field.dart';

class LocalTaskBuilderPage extends StatelessWidget {
  const LocalTaskBuilderPage({super.key, this.editingTask});

  final Task? editingTask;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<TaskBuilderCubit>()..load(editingTask),
      child: const _LocalTaskBuilderView(),
    );
  }
}

class _LocalTaskBuilderView extends StatelessWidget {
  const _LocalTaskBuilderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
      builder: (context, state) => switch (state) {
        TaskBuilderLoading() => const Center(
          child: CircularProgressIndicator(),
        ),
        TaskBuilderFailure(:final message) => Center(child: Text(message)),
        TaskBuilderLoaded(:final editingTask) => _LocalTaskEditor(
          task: editingTask,
        ),
      },
    );
  }
}

class _LocalTaskEditor extends StatelessWidget {
  const _LocalTaskEditor({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const TaskTitleField(),
          const SizedBox(height: AppSpacing.md),
          _LocalTaskTools(task: task),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(child: NodeGraph(nodes: task.nodes)),
          ),
        ],
      ),
    );
  }
}

class _LocalTaskTools extends StatelessWidget {
  const _LocalTaskTools({required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        IconButton(
          tooltip: 'Texteingabe hinzufügen',
          onPressed: () => context.read<TaskBuilderCubit>().addNodeToMainGraph(
            WorkflowPrimitive.stringInput,
          ),
          icon: const Icon(Icons.text_fields),
        ),
        IconButton(
          tooltip: 'Freigabe hinzufügen',
          onPressed: () => context.read<TaskBuilderCubit>().addNodeToMainGraph(
            WorkflowPrimitive.humanApproval,
          ),
          icon: const Icon(Icons.fact_check_outlined),
        ),
        FilledButton.icon(
          onPressed: task.nodes.isEmpty ? null : () => _execute(context),
          icon: const Icon(Icons.play_arrow),
          label: const Text('Ausführen'),
        ),
      ],
    );
  }

  Future<void> _execute(BuildContext context) async {
    final taskRunOrFailure = await serviceLocator<ExecuteTask>()(
      ExecuteTaskParams(task: task),
    );
    if (!context.mounted) return;
    final message = taskRunOrFailure.when(
      (_) => 'Aufgabe wurde gestartet.',
      (failure) => failure.message,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
