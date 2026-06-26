import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderPage extends StatelessWidget {
  const TaskBuilderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<TaskBuilderCubit>()..load(),
      child: const _TaskBuilderView(),
    );
  }
}

class _TaskBuilderView extends StatelessWidget {
  const _TaskBuilderView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
      builder: (context, state) => _TaskBuilderBody(state: state),
    );
  }
}

class _TaskBuilderBody extends StatelessWidget {
  const _TaskBuilderBody({required this.state});

  final TaskBuilderState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TaskBuilderCubit>();
    final promptNode = _promptNodeOrNull(state);
    return Column(
      children: [
        Toolbar(
          onAddPrompt: () => cubit.addPrimitive(WorkflowPrimitive.prompt),
        ),
        const SizedBox(height: AppSpacing.xxl),
        if (promptNode != null)
          PromptWidget(node: promptNode, cubit: cubit)
        else
          const CircularProgressIndicator(),
      ],
    );
  }

  WorkflowNode? _promptNodeOrNull(TaskBuilderState state) {
    if (state case TaskBuilderLoaded(:final taskDefinition)) {
      final selectedNode = taskDefinition.selectedNodeOrNull;
      if (selectedNode?.primitive == WorkflowPrimitive.prompt) {
        return selectedNode;
      }
      for (final node in taskDefinition.nodes) {
        if (node.primitive == WorkflowPrimitive.prompt) return node;
      }
    }
    return null;
  }
}
