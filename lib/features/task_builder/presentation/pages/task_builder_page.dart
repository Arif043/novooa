import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/syscat_theme.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/repositories/task_definition_repository.dart';
import '../../domain/usecases/get_draft_task_definition.dart';
import '../../domain/usecases/save_draft_task_definition.dart';
import '../../infrastructure/repositories/in_memory_task_definition_repository.dart';
import '../cubits/task_builder_cubit.dart';
import '../cubits/task_builder_state.dart';
import '../widgets/task_builder_app_bar.dart';
import '../widgets/workflow_builder_view.dart';

/// Einstiegsseite des Features „Aufgabe".
///
/// Besitzt den [TaskBuilderCubit] + das [TaskDefinitionRepository] und
/// schaltet im Build zwischen Loading / Failure / Empty / Loaded um.
/// Verwendet einen eigenen [Scaffold] mit feature-spezifischem
/// [TaskBuilderAppBar] — der globale AppBar wird vom `RootPage` für
/// diesen Tab ausgeblendet.
class TaskBuilderPage extends StatefulWidget {
  const TaskBuilderPage({super.key, this.repository});

  /// Optionaler DI-Hook: ermöglicht Tests, ein eigenes Repository zu
  /// injizieren. Im Produktionspfad wird der Default
  /// [InMemoryTaskDefinitionRepository] verwendet.
  final TaskDefinitionRepository? repository;

  @override
  State<TaskBuilderPage> createState() => _TaskBuilderPageState();
}

class _TaskBuilderPageState extends State<TaskBuilderPage> {
  late final TaskDefinitionRepository _repository;
  late final TaskBuilderCubit _cubit;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? InMemoryTaskDefinitionRepository();
    _cubit = TaskBuilderCubit(
      getDraftTaskDefinition: GetDraftTaskDefinition(_repository),
      saveDraftTaskDefinition: SaveDraftTaskDefinition(_repository),
    )..load();
  }

  @override
  void dispose() {
    _cubit.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(milliseconds: 1200),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: _TaskBuilderAppBarHost(
        cubit: _cubit,
        onPrimitiveTab: (primitive) async {
          await _cubit.addPrimitive(primitive);
          _showSnackBar('${primitive.label} hinzugefügt.');
        },
      ),
      body: AnimatedBuilder(
        animation: _cubit,
        builder: (context, _) => _TaskBuilderBody(
          state: _cubit.state,
          onRetry: _cubit.load,
          onPrimitiveAdded: (primitive) async {
            await _cubit.addPrimitive(primitive);
            _showSnackBar('Baustein hinzugefügt.');
          },
          onNodeSelected: _cubit.selectNode,
          onNodeDeleted: (NodeId nodeId) async {
            await _cubit.removeNode(nodeId);
            _showSnackBar('Baustein entfernt.');
          },
          onTitleChanged: _cubit.updateTitle,
          onObjectiveChanged: _cubit.updateObjective,
          onDescriptionChanged: (description) {
            final state = _cubit.state;
            if (state is! TaskBuilderLoaded) return;
            final selectedId = state.taskDefinition.selectedNodeId;
            _cubit.updateNodeDescription(selectedId, description);
          },
          onLogicModeChanged: (mode) {
            final state = _cubit.state;
            if (state is! TaskBuilderLoaded) return;
            final selectedId = state.taskDefinition.selectedNodeId;
            _cubit.updateNodeLogicMode(selectedId, mode);
          },
          onConditionChanged: (edit) {
            _cubit.updateEdgeCondition(
              from: edit.from,
              to: edit.to,
              conditionLabel: edit.label,
            );
          },
          onSave: () {
            _cubit.confirmSave();
            _showSnackBar('Entwurf gespeichert.');
          },
          onDiscard: () {
            _cubit.load();
            _showSnackBar('Änderungen verworfen.');
          },
        ),
      ),
    );
  }
}

class _TaskBuilderBody extends StatelessWidget {
  const _TaskBuilderBody({
    required this.state,
    required this.onRetry,
    required this.onPrimitiveAdded,
    required this.onNodeSelected,
    required this.onNodeDeleted,
    required this.onTitleChanged,
    required this.onObjectiveChanged,
    required this.onDescriptionChanged,
    required this.onLogicModeChanged,
    required this.onConditionChanged,
    required this.onSave,
    required this.onDiscard,
  });

  final TaskBuilderState state;
  final Future<void> Function() onRetry;
  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;
  final ValueChanged<NodeId> onNodeSelected;
  final ValueChanged<NodeId> onNodeDeleted;
  final ValueChanged<String> onTitleChanged;
  final ValueChanged<String> onObjectiveChanged;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<LogicMode> onLogicModeChanged;
  final ValueChanged<({NodeId from, NodeId to, String? label})> onConditionChanged;
  final VoidCallback onSave;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      TaskBuilderLoading() => const _LoadingView(),
      TaskBuilderFailure(:final message) => _FailureView(
        message: message,
        onRetry: () => onRetry(),
      ),
      TaskBuilderLoaded(:final taskDefinition)
          when taskDefinition.nodes.isEmpty =>
        _EmptyView(onPrimitiveAdded: onPrimitiveAdded),
      TaskBuilderLoaded(:final taskDefinition) => WorkflowBuilderView(
        taskDefinition: taskDefinition,
        activePrimitive: taskDefinition.selectedNodeOrNull?.primitive,
        onPrimitiveAdded: onPrimitiveAdded,
        onNodeSelected: onNodeSelected,
        onNodeDeleted: onNodeDeleted,
        onTitleChanged: onTitleChanged,
        onObjectiveChanged: onObjectiveChanged,
        onDescriptionChanged: onDescriptionChanged,
        onLogicModeChanged: onLogicModeChanged,
        onConditionChanged: onConditionChanged,
        onSave: onSave,
        onDiscard: onDiscard,
      ),
    };
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
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
          Icon(Icons.error_outline, size: 48, color: SyscatTheme.error),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
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

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.onPrimitiveAdded});

  final ValueChanged<WorkflowPrimitive> onPrimitiveAdded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.workspaces_outlined,
            size: 64,
            color: SyscatTheme.textHint,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Noch keine Bausteine',
            style: Theme.of(context).textTheme.displayLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Wähle oben einen Baustein-Tab, um deine Aufgabe zu starten.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: SyscatTheme.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Adapter, damit der [Scaffold] einen reaktiven [TaskBuilderAppBar]
/// als [PreferredSizeWidget] einsetzen kann. Hört auf den Cubit, um
/// den aktiven Tab bei Selektion zu aktualisieren.
class _TaskBuilderAppBarHost extends StatelessWidget
    implements PreferredSizeWidget {
  const _TaskBuilderAppBarHost({
    required this.cubit,
    required this.onPrimitiveTab,
  });

  final TaskBuilderCubit cubit;
  final ValueChanged<WorkflowPrimitive> onPrimitiveTab;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: cubit,
      builder: (context, _) {
        final state = cubit.state;
        final active = state is TaskBuilderLoaded
            ? state.taskDefinition.selectedNodeOrNull?.primitive
            : null;
        return TaskBuilderAppBar(
          activePrimitive: active,
          onPrimitiveTab: onPrimitiveTab,
        );
      },
    );
  }
}