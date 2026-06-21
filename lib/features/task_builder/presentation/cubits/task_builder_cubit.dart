import 'package:flutter/foundation.dart';

import '../../domain/entities/workflow_node.dart';
import '../../domain/usecases/get_draft_task_definition.dart';
import '../../domain/usecases/save_draft_task_definition.dart';
import 'task_builder_state.dart';

class TaskBuilderCubit extends ChangeNotifier {
  TaskBuilderCubit({
    required GetDraftTaskDefinition getDraftTaskDefinition,
    required SaveDraftTaskDefinition saveDraftTaskDefinition,
  }) : _getDraftTaskDefinition = getDraftTaskDefinition,
       _saveDraftTaskDefinition = saveDraftTaskDefinition;

  final GetDraftTaskDefinition _getDraftTaskDefinition;
  final SaveDraftTaskDefinition _saveDraftTaskDefinition;

  TaskBuilderState _state = const TaskBuilderLoading();

  TaskBuilderState get state => _state;

  Future<void> load() async {
    _emit(const TaskBuilderLoading());
    try {
      final taskDefinition = await _getDraftTaskDefinition.execute();
      _emit(TaskBuilderLoaded(taskDefinition));
    } catch (_) {
      _emit(const TaskBuilderFailure('Aufgabe konnte nicht geladen werden.'));
    }
  }

  Future<void> selectNode(NodeId nodeId) async {
    final currentState = _state;
    if (currentState is! TaskBuilderLoaded) return;
    final updatedTask = currentState.taskDefinition.selectNode(nodeId);
    await _saveDraftTaskDefinition.execute(updatedTask);
    _emit(TaskBuilderLoaded(updatedTask));
  }

  Future<void> addPrimitive(WorkflowPrimitive primitive) async {
    final currentState = _state;
    if (currentState is! TaskBuilderLoaded) return;
    final node = _buildNode(
      primitive,
      currentState.taskDefinition.nodes.length,
    );
    final updatedTask = currentState.taskDefinition.addNode(node);
    await _saveDraftTaskDefinition.execute(updatedTask);
    _emit(TaskBuilderLoaded(updatedTask));
  }

  WorkflowNode _buildNode(WorkflowPrimitive primitive, int index) {
    final number = index + 1;
    return WorkflowNode(
      id: NodeId('node.$number'),
      primitive: primitive,
      title: primitive.label,
      description: primitive.description,
    );
  }

  void _emit(TaskBuilderState state) {
    _state = state;
    notifyListeners();
  }
}

extension WorkflowPrimitiveLabels on WorkflowPrimitive {
  String get label {
    return switch (this) {
      WorkflowPrimitive.prompt => 'Prompt',
      WorkflowPrimitive.conditionalFlow => 'Conditional Flow',
      WorkflowPrimitive.iterativeRefinement => 'Iterative Refinement',
      WorkflowPrimitive.toolCall => 'Tool Call',
      WorkflowPrimitive.humanApproval => 'Human Approval',
      WorkflowPrimitive.validation => 'Validation',
    };
  }

  String get description {
    return switch (this) {
      WorkflowPrimitive.prompt => 'Formt Eingaben in einen Modellauftrag.',
      WorkflowPrimitive.conditionalFlow =>
        'Verzweigt den Ablauf anhand von Regeln.',
      WorkflowPrimitive.iterativeRefinement =>
        'Verbessert ein Ergebnis über mehrere Runden.',
      WorkflowPrimitive.toolCall =>
        'Bindet externe Aktionen oder Datenquellen ein.',
      WorkflowPrimitive.humanApproval => 'Wartet auf menschliche Freigabe.',
      WorkflowPrimitive.validation =>
        'Prüft Ergebnis, Schema oder Qualitätskriterien.',
    };
  }
}
