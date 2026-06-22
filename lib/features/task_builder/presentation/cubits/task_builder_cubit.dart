import 'package:flutter/foundation.dart';

import '../../domain/entities/task_definition.dart';
import '../../domain/entities/workflow_node.dart';
import '../../domain/usecases/get_draft_task_definition.dart';
import '../../domain/usecases/save_draft_task_definition.dart';
import 'task_builder_state.dart';

/// Zustandsverwaltung für den Aufgaben-Builder.
///
/// Bleibt bewusst ein [ChangeNotifier] (kein `flutter_bloc` im `pubspec`).
/// Jede Mutation folgt dem gleichen Muster:
/// 1. State-Guards (nur in [TaskBuilderLoaded] aktiv).
/// 2. Domain-Operation aufrufen (liefert neue Immutable-Instanz).
/// 3. Sofort persistieren via [SaveDraftTaskDefinition].
/// 4. Neuen State emittieren.
class TaskBuilderCubit extends ChangeNotifier {
  TaskBuilderCubit({
    required GetDraftTaskDefinition getDraftTaskDefinition,
    required SaveDraftTaskDefinition saveDraftTaskDefinition,
  })  : _getDraftTaskDefinition = getDraftTaskDefinition,
        _saveDraftTaskDefinition = saveDraftTaskDefinition;

  final GetDraftTaskDefinition _getDraftTaskDefinition;
  final SaveDraftTaskDefinition _saveDraftTaskDefinition;

  TaskBuilderState _state = const TaskBuilderLoading();

  TaskBuilderState get state => _state;

  /// Initiales Laden. Idempotent — mehrfach aufrufbar (z. B. „Erneut
  /// versuchen" nach einem Fehler).
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
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final updated = task.selectNode(nodeId);
    await _saveAndEmit(updated);
  }

  Future<void> addPrimitive(WorkflowPrimitive primitive) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, task.nodes.length);
    final updated = task.addNode(node);
    await _saveAndEmit(updated);
  }

  Future<void> updateTitle(String title) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    if (task.title == title) return;
    await _saveAndEmit(task.copyWith(title: title));
  }

  Future<void> updateObjective(String objective) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    if (task.objective == objective) return;
    await _saveAndEmit(task.copyWith(objective: objective));
  }

  Future<void> updateNodeDescription(NodeId nodeId, String description) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final index = task.nodes.indexWhere((node) => node.id == nodeId);
    if (index == -1) return;
    final currentNode = task.nodes[index];
    if (currentNode.description == description) return;
    final updatedNode = currentNode.copyWith(description: description);
    final newNodes = [...task.nodes]..[index] = updatedNode;
    await _saveAndEmit(task.copyWith(nodes: newNodes));
  }

  Future<void> removeNode(NodeId nodeId) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final updated = task.removeNode(nodeId);
    await _saveAndEmit(updated);
  }

  Future<void> updateNodeLogicMode(NodeId nodeId, LogicMode mode) async {
    final task = _loadedTaskOrNull();
    if (task == null) return;
    final index = task.nodes.indexWhere((node) => node.id == nodeId);
    if (index == -1) return;
    final currentNode = task.nodes[index];
    if (currentNode.logicMode == mode) return;
    final updatedNode = currentNode.copyWith(logicMode: mode);
    final newNodes = [...task.nodes]..[index] = updatedNode;
    await _saveAndEmit(task.copyWith(nodes: newNodes));
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

  /// Public-API-Marker, der vom Footer verwendet wird, um einen
  /// expliziten „Speichern"-Tap zu kennzeichnen. Die Persistenz ist
  /// aufgrund von Invariante 5 ohnehin nach jeder Mutation erledigt — die
  /// UI bestätigt dem User nur visuell (SnackBar).
  void confirmSave() {
    // Aktuell No-op: die In-Memory-Persistenz läuft synchron. Sobald
    // Firestore angebunden ist, könnte hier ein expliziter
    // Round-Trip-Indikator eingebaut werden.
  }

  TaskDefinition? _loadedTaskOrNull() {
    final current = _state;
    return current is TaskBuilderLoaded ? current.taskDefinition : null;
  }

  Future<void> _saveAndEmit(TaskDefinition updated) async {
    await _saveDraftTaskDefinition.execute(updated);
    _emit(TaskBuilderLoaded(updated));
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

/// Deutsche UI-Labels und Beschreibungen für die sechs
/// [WorkflowPrimitive]-Werte. Synchron zur Tabelle in
/// `docs/features/aufgabe.md` § Primitives halten.
extension WorkflowPrimitiveLabels on WorkflowPrimitive {
  String get label {
    return switch (this) {
      WorkflowPrimitive.prompt => 'Prompt',
      WorkflowPrimitive.conditionalFlow => 'Bedingter Ablauf',
      WorkflowPrimitive.iterativeRefinement => 'Iterative Verfeinerung',
      WorkflowPrimitive.toolCall => 'Werkzeug-Aufruf',
      WorkflowPrimitive.humanApproval => 'Freigabe',
      WorkflowPrimitive.validation => 'Validierung',
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