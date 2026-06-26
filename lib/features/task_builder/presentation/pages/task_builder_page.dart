import 'package:flutter/material.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/core/theme/app_spacing.dart';

import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import '../widgets/prompt_widget.dart';
import '../widgets/toolbar.dart';

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
    return AnimatedBuilder(
      animation: _cubit,
      builder: (context, _) =>
          _TaskBuilderBody(state: _cubit.state, cubit: _cubit),
    );
  }
}

class _TaskBuilderBody extends StatelessWidget {
  const _TaskBuilderBody({required this.state, required this.cubit});

  final TaskBuilderState state;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TaskBuilderLoading() => const Center(child: CircularProgressIndicator()),
      TaskBuilderFailure(:final message) => _FailureState(message: message),
      TaskBuilderLoaded(:final taskDefinition) => _LoadedTaskBuilder(
        taskDefinition: taskDefinition,
        cubit: cubit,
      ),
    };
  }
}

class _LoadedTaskBuilder extends StatelessWidget {
  const _LoadedTaskBuilder({required this.taskDefinition, required this.cubit});

  final TaskDefinition taskDefinition;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final selectedNode = taskDefinition.selectedNodeOrNull;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Toolbar(onAddPrompt: _addPrompt),
          const SizedBox(height: AppSpacing.lg),
          _NodeSelector(taskDefinition: taskDefinition, cubit: cubit),
          const SizedBox(height: AppSpacing.lg),
          _SelectedNodePanel(node: selectedNode, cubit: cubit),
        ],
      ),
    );
  }

  void _addPrompt() {
    cubit.addPrimitive(WorkflowPrimitive.prompt);
  }
}

class _NodeSelector extends StatelessWidget {
  const _NodeSelector({required this.taskDefinition, required this.cubit});

  final TaskDefinition taskDefinition;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: taskDefinition.nodes.map(_chipFor).toList(),
    );
  }

  Widget _chipFor(WorkflowNode node) {
    return ChoiceChip(
      label: Text(node.title),
      selected: node.id == taskDefinition.selectedNodeId,
      onSelected: (_) => cubit.selectNode(node.id),
    );
  }
}

class _SelectedNodePanel extends StatelessWidget {
  const _SelectedNodePanel({required this.node, required this.cubit});

  final WorkflowNode? node;
  final TaskBuilderCubit cubit;

  @override
  Widget build(BuildContext context) {
    final selectedNode = node;
    if (selectedNode == null) return const _EmptyState();
    if (selectedNode.primitive == WorkflowPrimitive.prompt) {
      return PromptWidget(node: selectedNode, cubit: cubit);
    }
    return _UnsupportedNodeState(node: selectedNode);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Text('Wähle einen Baustein aus oder füge einen Prompt hinzu.'),
      ),
    );
  }
}

class _UnsupportedNodeState extends StatelessWidget {
  const _UnsupportedNodeState({required this.node});

  final WorkflowNode node;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text('${node.title} wird als Nächstes umgesetzt.'),
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(child: Text(message));
  }
}
