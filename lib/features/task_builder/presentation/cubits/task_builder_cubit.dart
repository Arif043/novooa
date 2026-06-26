import 'package:bloc/bloc.dart';

import '../../domain/entities/prompt_node_config.dart';
import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/usecases/get_draft_task_definition.dart';
import '../../domain/usecases/save_draft_task_definition.dart';
import 'task_builder_state.dart';
import 'workflow_primitive_labels.dart';

/// Zustandsverwaltung für den Aufgaben-Builder.
///
/// Jede Mutation folgt dem gleichen Muster:
/// 1. State-Guards (nur in [TaskBuilderLoaded] aktiv).
/// 2. Domain-Operation aufrufen (liefert neue Immutable-Instanz).
/// 3. Sofort persistieren via [SaveDraftTaskDefinition].
/// 4. Neuen State emittieren.
class TaskBuilderCubit extends Cubit<TaskBuilderState> {
  TaskBuilderCubit({
    required GetDraftTaskDefinition getDraftTaskDefinition,
    required SaveDraftTaskDefinition saveDraftTaskDefinition,
  }) : _getDraftTaskDefinition = getDraftTaskDefinition,
       _saveDraftTaskDefinition = saveDraftTaskDefinition,
       super(const TaskBuilderLoading());

  final GetDraftTaskDefinition _getDraftTaskDefinition;
  final SaveDraftTaskDefinition _saveDraftTaskDefinition;

  Future<void> load() async {
    emit(const TaskBuilderLoading());
    try {
      final taskDefinition = await _getDraftTaskDefinition.execute();
      if (isClosed) return;
      emit(TaskBuilderLoaded(taskDefinition));
    } catch (_) {
      if (isClosed) return;
      emit(const TaskBuilderFailure('Aufgabe konnte nicht geladen werden.'));
    }
  }

  Future<void> selectNode(NodeId nodeId) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    await _saveAndEmit(task.selectNode(nodeId));
  }

  Future<void> addPrimitive(WorkflowPrimitive primitive) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, task.nodes.length);
    await _saveAndEmit(task.addNode(node));
  }

  Future<void> updateTitle(String title) async {
    final task = _loadedTaskOrNull();
    if (task == null || task.title == title) return;
    await _saveAndEmit(task.copyWith(title: title));
  }

  Future<void> updateObjective(String objective) async {
    final task = _loadedTaskOrNull();
    if (task == null || task.objective == objective) return;
    await _saveAndEmit(task.copyWith(objective: objective));
  }

  Future<void> updateNodeDescription(NodeId nodeId, String description) {
    return _updateNode(nodeId, (node) {
      if (node.description == description) return node;
      return node.copyWith(description: description);
    });
  }

  Future<void> updateNodeTitle(NodeId nodeId, String title) {
    return _updateNode(nodeId, (node) {
      if (node.title == title) return node;
      return node.copyWith(title: title);
    });
  }

  Future<void> removeNode(NodeId nodeId) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    await _saveAndEmit(task.removeNode(nodeId));
  }

  Future<void> updateNodeLogicMode(NodeId nodeId, LogicMode mode) {
    return _updateNode(nodeId, (node) {
      if (node.logicMode == mode) return node;
      return node.copyWith(logicMode: mode);
    });
  }

  Future<void> updatePromptInstruction(NodeId nodeId, String instruction) {
    return _updateNode(nodeId, (node) {
      final promptConfig = node.promptConfig.copyWith(instruction: instruction);
      return node.copyWith(promptConfig: promptConfig);
    });
  }

  Future<void> updatePromptOutputType(
    NodeId nodeId,
    PromptOutputType outputType,
  ) {
    return _updateNode(nodeId, (node) {
      final promptConfig = node.promptConfig.copyWith(outputType: outputType);
      return node.copyWith(promptConfig: promptConfig);
    });
  }

  Future<void> updatePromptChoice({
    required NodeId nodeId,
    required int index,
    required String value,
  }) {
    return _updateNode(nodeId, (node) {
      if (index < 0 || index >= node.promptConfig.choices.length) return node;
      if (node.promptConfig.choices[index] == value) return node;
      return node.copyWith(
        promptConfig: node.promptConfig.updateChoice(index, value),
      );
    });
  }

  Future<void> updateEdgeCondition({
    required NodeId from,
    required NodeId to,
    required String? conditionLabel,
  }) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final updated = task.updateEdgeCondition(
      from: from,
      to: to,
      conditionLabel: conditionLabel,
    );
    await _saveAndEmit(updated);
  }

  void confirmSave() {}

  TaskDefinition? _loadedTaskOrNull() {
    final current = state;
    return current is TaskBuilderLoaded ? current.taskDefinition : null;
  }

  Future<void> _saveAndEmit(TaskDefinition updated) async {
    await _saveDraftTaskDefinition.execute(updated);
    if (isClosed) return;
    emit(TaskBuilderLoaded(updated));
  }

  Future<void> _updateNode(
    NodeId nodeId,
    WorkflowNode Function(WorkflowNode node) update,
  ) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final index = task.nodes.indexWhere((node) => node.id == nodeId);
    if (index == -1) return;
    final currentNode = task.nodes[index];
    final updatedNode = update(currentNode);
    if (identical(updatedNode, currentNode)) return;
    final newNodes = [...task.nodes]..[index] = updatedNode;
    await _saveAndEmit(task.copyWith(nodes: newNodes));
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
}
