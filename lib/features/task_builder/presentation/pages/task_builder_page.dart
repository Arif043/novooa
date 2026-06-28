import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/task.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/domain/usecases/execute_task.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderPage extends StatelessWidget {
  final Task? editingTaskOrNull;

  const TaskBuilderPage({super.key, this.editingTaskOrNull});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<TaskBuilderCubit>()..load(editingTaskOrNull),
      child: const _TaskBuilderView(),
    );
  }
}

class _TaskBuilderView extends StatelessWidget {
  const _TaskBuilderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBuilderCubit, TaskBuilderState>(builder: (context, state) => _TaskBuilderBody(state: state));
  }
}

class _TaskBuilderBody extends StatelessWidget {
  const _TaskBuilderBody({required this.state});

  final TaskBuilderState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    return Column(
      children: [
        FilledButton(
          onPressed: () {
            final task = cubit.loadedTaskOrNull();
            if (task == null) return;
            debugPrint(task.toString());
            serviceLocator<ExecuteTask>()(ExecuteTaskParams(task: task));
          },
          child: Text('Run Task'),
        ),
        Toolbar(),
        const SizedBox(height: AppSpacing.xxl),
        _nodeGraph(state),
      ],
    );
  }

  Widget _nodeGraph(TaskBuilderState state) {
    if (state case TaskBuilderLoaded(:final editingTask)) {
      return Column(children: editingTask.nodes.map(_nodeWidgetOrNull).toList());
    }
    return const SizedBox.shrink();
  }

  Widget _nodeWidgetOrNull(WorkflowNode node) {
    return switch (node.config.primitive) {
      .prompt => PromptWidget(node: node),
      .conditional => BranchWidget(),
      _ => SizedBox.shrink()
    };
  }
}
