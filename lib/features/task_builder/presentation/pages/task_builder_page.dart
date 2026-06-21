import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/usecases/get_draft_task_definition.dart';
import '../../domain/usecases/save_draft_task_definition.dart';
import '../../infrastructure/repositories/in_memory_task_definition_repository.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import '../widgets/node_inspector.dart';
import '../widgets/primitive_palette.dart';
import '../widgets/workflow_canvas.dart';

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
    final repository = InMemoryTaskDefinitionRepository();
    _cubit = TaskBuilderCubit(
      getDraftTaskDefinition: GetDraftTaskDefinition(repository),
      saveDraftTaskDefinition: SaveDraftTaskDefinition(repository),
    )..load();
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
      builder: (context, child) =>
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
      TaskBuilderFailure(:final message) => _FailureView(
        message: message,
        onRetry: cubit.load,
      ),
      TaskBuilderLoaded(:final taskDefinition)
          when taskDefinition.nodes.isEmpty =>
        const _EmptyView(),
      TaskBuilderLoaded(:final taskDefinition) => WorkflowBuilderView(
        taskDefinition: taskDefinition,
        onPrimitiveAdded: cubit.addPrimitive,
        onNodeSelected: cubit.selectNode,
      ),
    };
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Diese Aufgabe hat noch keine Bausteine.',
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
          ),
        ],
      ),
    );
  }
}

class WorkflowBuilderView extends StatelessWidget {
  const WorkflowBuilderView({
    super.key,
    required this.taskDefinition,
    required this.onPrimitiveAdded,
    required this.onNodeSelected,
  });

  final TaskDefinition taskDefinition;
  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;
  final ValueChanged<NodeId> onNodeSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 860) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              SizedBox(height: 320, child: _palette),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 420, child: _canvas),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(height: 280, child: _inspector),
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 240, child: _palette),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _canvas),
              const SizedBox(width: AppSpacing.lg),
              SizedBox(width: 280, child: _inspector),
            ],
          ),
        );
      },
    );
  }

  Widget get _palette => PrimitivePalette(onPrimitiveAdded: onPrimitiveAdded);

  Widget get _canvas => WorkflowCanvas(
    taskDefinition: taskDefinition,
    onNodeSelected: onNodeSelected,
  );

  Widget get _inspector => NodeInspector(node: taskDefinition.selectedNode);
}
