import 'package:bloc/bloc.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'task_builder_state.dart';
import 'workflow_primitive_labels.dart';

part 'task_builder_branch_mutations.dart';
part 'task_builder_graph_mutations.dart';
part 'task_builder_iterative_refinement_mutations.dart';
part 'task_builder_prompt_mutations.dart';

/// Zustandsverwaltung für den Aufgaben-Builder.
///
/// Jede Mutation folgt dem gleichen Muster:
/// 1. State-Guards (nur in [TaskBuilderLoaded] aktiv).
/// 2. Domain-Operation aufrufen (liefert neue Immutable-Instanz).
/// 3. Sofort persistieren via [SaveDraftTaskDefinition].
/// 4. Neuen State emittieren.
class TaskBuilderCubit extends Cubit<TaskBuilderState> {
  final TaskRepository _repository;

  TaskBuilderCubit({required TaskRepository repository})
    : _repository = repository,
      super(const TaskBuilderLoading());

  Future<void> load(Task? editingTask) async {
    editingTask ??= Task.empty();
    emit(const TaskBuilderLoading());
    try {
      if (isClosed) return;
      emit(TaskBuilderLoaded(editingTask));
    } catch (_) {
      if (isClosed) return;
      emit(const TaskBuilderFailure('Aufgabe konnte nicht geladen werden.'));
    }
  }

  Future<void> selectNode(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    await _saveAndEmit(task.selectNode(nodeId));
  }

  Future<void> addNodeToMainGraph(WorkflowPrimitive primitive) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, task.nodes.length);
    await _saveAndEmit(task.addNode(node));
  }

  Future<void> updateTitle(String title) async {
    final task = loadedTaskOrNull();
    if (task == null || task.title == title) return;
    await _saveAndEmit(task.copyWith(title: title));
  }

  Future<void> updateObjective(String objective) async {
    final task = loadedTaskOrNull();
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
    final task = loadedTaskOrNull();
    if (task == null) return;
    await _saveAndEmit(task.removeNode(nodeId));
  }

  Future<void> updateEdgeCondition({
    required NodeId from,
    required NodeId to,
    required String? conditionLabel,
  }) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final updated = task.updateEdgeCondition(
      from: from,
      to: to,
      conditionLabel: conditionLabel,
    );
    await _saveAndEmit(updated);
  }

  void confirmSave() {}

  Task? loadedTaskOrNull() {
    final current = state;
    return current is TaskBuilderLoaded ? current.editingTask : null;
  }

  Future<void> _saveAndEmit(Task updated) async {
    await _repository.saveTask(updated);
    if (isClosed) return;
    emit(TaskBuilderLoaded(updated));
  }

  WorkflowNode _buildNode(WorkflowPrimitive primitive, int index) {
    final number = index + 1;
    return WorkflowNode(
      id: NodeId('node.$number'),
      config: NodeConfig.initial(primitive),
      title: primitive.label,
      description: primitive.description,
    );
  }
}
