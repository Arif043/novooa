import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_node.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_cubit.dart';
import 'package:syscat2/features/task_builder/presentation/cubits/task_builder_state.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/prompt_widget.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/toolbar.dart';

class TaskBuilderPage extends StatefulWidget {
  const TaskBuilderPage({super.key});

  @override
  State<TaskBuilderPage> createState() => _TaskBuilderPageState();
}

class _TaskBuilderPageState extends State<TaskBuilderPage> {
  late final TaskBuilderCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = serviceLocator<TaskBuilderCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskBuilderCubit, TaskBuilderState>(
      builder: (context, state) {
        return AnimatedBuilder(
          animation: _cubit,
          builder: (context, _) {
            final promptNode = _promptNodeOrNull(_cubit.state);
            return Column(
              children: [
                Toolbar(onAddPrompt: _addPrompt),
                const SizedBox(height: AppSpacing.xxl),
                if (promptNode != null)
                  PromptWidget(node: promptNode, cubit: _cubit)
                else
                  const CircularProgressIndicator(),
              ],
            );
          },
        );
      },
    );
  }

  void _addPrompt() {
    _cubit.addPrimitive(WorkflowPrimitive.prompt);
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
