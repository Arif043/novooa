import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/task_builder/domain/entities/employee_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/knowledge_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_attachment.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';
import 'package:syscat2/features/task_builder/domain/repositories/task_repository.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'task_builder_state.dart';
import 'workflow_primitive_labels.dart';
part 'task_builder_branch_mutations.dart';
part 'task_builder_condition_branch_mutations.dart';
part 'task_builder_attachment_mutations.dart';
part 'task_builder_graph_mutations.dart';
part 'task_builder_iterative_refinement_mutations.dart';
part 'task_builder_human_approval_mutations.dart';
part 'task_builder_dialog_input_mutations.dart';
part 'task_builder_media_input_mutations.dart';
part 'task_builder_model_inference_mutations.dart';
part 'task_builder_for_each_mutations.dart';
part 'task_builder_prompt_mutations.dart';
part 'task_builder_script_mutations.dart';
part 'task_builder_string_input_mutations.dart';
part 'task_builder_write_file_mutations.dart';
part 'task_builder_read_file_mutations.dart';
part 'task_builder_send_message_mutations.dart';
part 'task_builder_notification_send_mutations.dart';
part 'task_builder_document_lookup_mutations.dart';
part 'task_builder_save_document_mutations.dart';
part 'task_builder_table_from_collection_mutations.dart';

/// Zustandsverwaltung für den Aufgaben-Builder.
///
/// Jede Mutation folgt dem gleichen Muster:
/// 1. State-Guards (nur in [TaskBuilderLoaded] aktiv).
/// 2. Domain-Operation aufrufen (liefert neue Immutable-Instanz).
/// 3. Neuen State emittieren.
/// 4. Persistenz gebündelt via [TaskRepository] auslösen.
class TaskBuilderCubit extends Cubit<TaskBuilderState> {
  static const _saveDebounceDuration = Duration(milliseconds: 800);

  final TaskRepository repository;
  Timer? _saveTimer;
  Task? _pendingSaveTask;
  Future<void> _saveQueue = Future.value();

  TaskBuilderCubit({required this.repository})
    : super(const TaskBuilderLoading());

  Future<void> load(Task? taskFromNavigation) async {
    emit(const TaskBuilderLoading());
    try {
      final editingTask = await _taskForLoad(taskFromNavigation);
      if (taskFromNavigation == null) await repository.saveTask(editingTask);
      if (isClosed) return;
      emit(TaskBuilderLoaded(editingTask));
    } catch (error, stackTrace) {
      logException(
        message: 'Aufgabe konnte nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'task_builder',
      );
      if (isClosed) return;
      emit(const TaskBuilderFailure('Aufgabe konnte nicht geladen werden.'));
    }
  }

  Future<Task> _taskForLoad(Task? taskFromNavigation) async {
    if (taskFromNavigation == null) return Task.empty();
    final tasks = await repository.watchTasks().first;
    for (final task in tasks) {
      if (task.id == taskFromNavigation.id) return task;
    }
    return taskFromNavigation;
  }

  @override
  Future<void> close() async {
    _saveTimer?.cancel();
    await _flushPendingSave();
    return super.close();
  }

  Future<void> selectNode(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    await _saveAndEmit(task.selectNode(nodeId));
  }

  Future<void> addNodeToMainGraph(WorkflowPrimitive primitive) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final node = _buildNode(primitive, _nextNodeNumber(task.graph), task.graph);
    final previousSelection = task.selectedNodeId;
    await _saveAndEmit(task.addNode(node));
    await _syncNewSuccessorIfNeeded(previousSelection);
  }

  Future<void> addChannelEventNodeToMainGraph(ChannelEventKind kind) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final nodeNumber = _nextNodeNumber(task.graph);
    final node = _buildNode(
      WorkflowPrimitive.readChannelEvent,
      nodeNumber,
      task.graph,
    );
    final configuredNode = node.copyWith(
      title: _channelEventTitle(kind),
      description: _channelEventDescription(kind),
      outputName: _uniqueOutputName(
        task.graph,
        '',
        _outputNameForKind(kind, nodeNumber),
      ),
      config: ReadChannelEventNodeConfig(kind: kind),
    );
    await _saveAndEmit(task.addNode(configuredNode));
  }

  Future<void> addSendMessageNodeToMainGraph(ChannelEventKind kind) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final nodeNumber = _nextNodeNumber(task.graph);
    final node = _buildNode(
      WorkflowPrimitive.sendChannelMessage,
      nodeNumber,
      task.graph,
    );
    final configuredNode = node.copyWith(
      title: _sendMessageTitle(kind),
      description: _sendMessageDescription(kind),
      outputName: _uniqueOutputName(
        task.graph,
        '',
        _outputNameForSendKind(kind, nodeNumber),
      ),
      config: SendChannelMessageNodeConfig.initial().copyWith(kind: kind),
    );
    await _saveAndEmit(task.addNode(configuredNode));
  }

  Future<void> updateTitle(String title) async {
    final task = loadedTaskOrNull();
    if (task == null || task.title == title) return;
    await _saveAndEmit(task.copyWith(title: title));
  }

  Future<void> restoreTask(Task task) {
    return _saveAndEmit(task);
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

  Future<void> updateNodeOutputName(NodeId nodeId, String value) {
    final task = loadedTaskOrNull();
    if (task == null) return Future.value();
    final normalizedName = _normalizedOutputName(value);
    if (normalizedName.isEmpty) return Future.value();
    return _updateNode(nodeId, (node) {
      final outputName = _uniqueOutputName(
        task.graph,
        node.outputName,
        normalizedName,
      );
      if (node.outputName == outputName) return node;
      return node.copyWith(outputName: outputName);
    });
  }

  Future<void> removeNode(NodeId nodeId) async {
    final task = loadedTaskOrNull();
    if (task == null) return;
    final result = _removeNodeFromGraph(task.graph, nodeId);
    if (!result.changed) return;
    await _saveAndEmit(
      task.copyWith(
        graph: result.graph,
        selectedNodeId: _selectionAfterRemove(task, result.graph),
      ),
    );
  }

  ({WorkflowGraph graph, bool changed}) _removeNodeFromGraph(
    WorkflowGraph graph,
    NodeId nodeId,
  ) {
    if (graph.nodes.any((node) => node.id == nodeId)) {
      return (graph: graph.removeNode(nodeId), changed: true);
    }
    for (var index = 0; index < graph.nodes.length; index++) {
      final result = _removeNodeFromBranches(graph.nodes[index], nodeId);
      if (!result.changed) continue;
      final nodes = [...graph.nodes]..[index] = result.node;
      return (graph: graph.copyWith(nodes: nodes), changed: true);
    }
    return (graph: graph, changed: false);
  }

  ({WorkflowNode node, bool changed}) _removeNodeFromBranches(
    WorkflowNode node,
    NodeId nodeId,
  ) {
    if (node.config case final ConditionalNodeConfig config) {
      for (var index = 0; index < config.branches.length; index++) {
        final branch = config.branches[index];
        final result = _removeNodeFromGraph(branch.graph, nodeId);
        if (!result.changed) continue;
        final branches = [...config.branches]
          ..[index] = branch.copyWith(graph: result.graph);
        return (
          node: node.copyWith(config: config.copyWith(branches: branches)),
          changed: true,
        );
      }
    }
    if (node.config case final ForEachNodeConfig config) {
      final result = _removeNodeFromGraph(config.graph, nodeId);
      if (result.changed) {
        return (
          node: node.copyWith(config: config.copyWith(graph: result.graph)),
          changed: true,
        );
      }
    }
    return (node: node, changed: false);
  }

  NodeId _selectionAfterRemove(Task task, WorkflowGraph graph) {
    if (_containsNode(graph, task.selectedNodeId)) return task.selectedNodeId;
    if (graph.nodes.isEmpty) return const NodeId('');
    return graph.nodes.last.id;
  }

  bool _containsNode(WorkflowGraph graph, NodeId nodeId) {
    for (final node in graph.nodes) {
      if (node.id == nodeId) return true;
      if (node.config case final ConditionalNodeConfig config) {
        if (config.branches.any(
          (branch) => _containsNode(branch.graph, nodeId),
        )) {
          return true;
        }
      }
      if (node.config case final ForEachNodeConfig config) {
        if (_containsNode(config.graph, nodeId)) return true;
      }
    }
    return false;
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

  Task? loadedTaskOrNull() {
    final current = state;
    return current is TaskBuilderLoaded ? current.editingTask : null;
  }

  Future<void> _saveAndEmit(Task updated) {
    if (isClosed) return Future.value();
    emit(TaskBuilderLoaded(updated));
    _scheduleSave(updated);
    return Future.value();
  }

  void _scheduleSave(Task task) {
    _pendingSaveTask = task;
    _saveTimer?.cancel();
    _saveTimer = Timer(_saveDebounceDuration, () {
      unawaited(_flushPendingSave());
    });
  }

  Future<void> _flushPendingSave() {
    final task = _pendingSaveTask;
    if (task == null) return _saveQueue;
    _pendingSaveTask = null;
    _saveQueue = _saveQueue.then((_) => _persistTask(task));
    return _saveQueue;
  }

  Future<void> _persistTask(Task task) async {
    try {
      await repository.saveTask(task);
    } catch (error, stackTrace) {
      logException(
        message: 'Aufgabe konnte nicht gespeichert werden.',
        name: 'TaskBuilderCubit',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  WorkflowNode _buildNode(
    WorkflowPrimitive primitive,
    int number,
    WorkflowGraph graph,
  ) {
    // Dialogeingabe-Bausteine haben immer mehrere, eigenständig benannte
    // Outputs (siehe _collectOutputNames) und deshalb nie einen eigenen
    // Ausgabenamen.
    final outputName = primitive == WorkflowPrimitive.dialogInput
        ? ''
        : _uniqueOutputName(graph, '', _outputNameFor(primitive, number));
    return WorkflowNode(
      id: NodeId('node.$number'),
      config: _initialConfig(primitive, graph),
      title: primitive.label,
      description: primitive.description,
      outputName: outputName,
    );
  }

  /// [NodeConfig.initial] liefert für Dialogeingabe-Bausteine ein Feld mit
  /// dem festen Namen "Antwort" — ohne Korrektur würde ein zweiter
  /// Dialogeingabe-Baustein denselben, nicht mehr eindeutigen Namen tragen.
  NodeConfig _initialConfig(WorkflowPrimitive primitive, WorkflowGraph graph) {
    final config = NodeConfig.initial(primitive);
    if (config is DialogInputNodeConfig && config.fields.isNotEmpty) {
      final uniqueName = _uniqueOutputName(graph, '', config.fields.first.name);
      return config.copyWith(
        fields: [
          config.fields.first.copyWith(name: uniqueName),
          ...config.fields.skip(1),
        ],
      );
    }
    return config;
  }

  int _nextNodeNumber(WorkflowGraph graph) {
    final ids = _nodeIdsIn(graph);
    var number = 1;
    while (ids.contains('node.$number')) {
      number += 1;
    }
    return number;
  }

  Set<String> _nodeIdsIn(WorkflowGraph graph) {
    final ids = <String>{};
    _collectNodeIds(graph, ids);
    return ids;
  }

  void _collectNodeIds(WorkflowGraph graph, Set<String> ids) {
    for (final node in graph.nodes) {
      ids.add(node.id.value);
      if (node.config case final ConditionalNodeConfig config) {
        for (final branch in config.branches) {
          _collectNodeIds(branch.graph, ids);
        }
      }
      if (node.config case final ForEachNodeConfig config) {
        _collectNodeIds(config.graph, ids);
      }
    }
  }

  String _normalizedOutputName(String value) {
    final sanitized = value.trim().replaceAll(RegExp(r'[^\w]'), '');
    if (sanitized.isEmpty) return '';
    if (RegExp(r'^\d').hasMatch(sanitized)) return 'n$sanitized';
    return sanitized;
  }

  /// Alle bereits vergebenen fachlichen Ausgabenamen im gesamten Graphen —
  /// sowohl der `outputName` eines Bausteins mit genau einem Output als auch
  /// jeder Feldname eines Bausteins mit mehreren fachlichen Outputs
  /// (strukturierte Prompt-Ausgabe, Dialogeingabe). Da referenceName als
  /// Konzept entfällt, ist das ein einziger, flacher, graph-weiter
  /// Namensraum statt einer Prüfung pro Knoten.
  Set<String> _allOutputNames(WorkflowGraph graph) {
    final names = <String>{};
    _collectOutputNames(graph, names);
    return names;
  }

  void _collectOutputNames(WorkflowGraph graph, Set<String> names) {
    for (final node in graph.nodes) {
      if (node.config case PromptNodeConfig(
        outputType: PromptOutputType.structured,
        :final structuredFields,
      )) {
        for (final field in structuredFields) {
          final name = field.name.trim();
          if (name.isNotEmpty) names.add(name);
        }
      } else if (node.config case DialogInputNodeConfig(:final fields)) {
        for (final field in fields) {
          final name = field.name.trim();
          if (name.isNotEmpty) names.add(name);
        }
      } else {
        final name = node.outputName.trim();
        if (name.isNotEmpty) names.add(name);
      }
      if (node.config case ConditionalNodeConfig(:final branches)) {
        for (final branch in branches) {
          _collectOutputNames(branch.graph, names);
        }
      }
      if (node.config case ForEachNodeConfig(graph: final nestedGraph)) {
        _collectOutputNames(nestedGraph, names);
      }
    }
  }

  /// Liefert [candidate] unverändert, wenn er (abgesehen von [previousName],
  /// dem bisherigen Namen derselben Stelle) noch frei ist — sonst mit einem
  /// `_2`/`_3`-Suffix, bis er eindeutig ist.
  String _uniqueOutputName(
    WorkflowGraph graph,
    String previousName,
    String candidate,
  ) {
    final taken = _allOutputNames(graph)..remove(previousName);
    if (!taken.contains(candidate)) return candidate;
    var suffix = 2;
    while (taken.contains('${candidate}_$suffix')) {
      suffix += 1;
    }
    return '${candidate}_$suffix';
  }

  String _outputNameFor(WorkflowPrimitive primitive, int number) {
    return '${_outputBaseFor(primitive)}$number';
  }

  String _outputBaseFor(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.stringInput => 'input',
      WorkflowPrimitive.script => 'script',
      WorkflowPrimitive.prompt => 'prompt',
      WorkflowPrimitive.conditional => 'condition',
      WorkflowPrimitive.iterativeRefinement => 'refine',
      WorkflowPrimitive.writeFile => 'writeFile',
      WorkflowPrimitive.readFile => 'readFile',
      WorkflowPrimitive.readEmail => 'email',
      WorkflowPrimitive.readChannelEvent => 'message',
      WorkflowPrimitive.sendChannelMessage => 'send',
      WorkflowPrimitive.notificationSend => 'notification',
      WorkflowPrimitive.toolCall => 'tool',
      WorkflowPrimitive.humanApproval => 'approval',
      WorkflowPrimitive.dialogInput => 'dialog',
      WorkflowPrimitive.mediaInput => 'media',
      WorkflowPrimitive.modelInference => 'model',
      WorkflowPrimitive.forEach => 'element',
      WorkflowPrimitive.documentLookup => 'datensatz',
      WorkflowPrimitive.saveDocument => 'speichern',
      WorkflowPrimitive.tableFromCollection => 'tabelle',
      WorkflowPrimitive.validation => 'validation',
    };
  }

  String _outputNameForKind(ChannelEventKind kind, int number) {
    return '${kind.name}$number';
  }

  String _outputNameForSendKind(ChannelEventKind kind, int number) {
    return 'send${kind.name}$number';
  }

  String _channelEventTitle(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email => 'E-Mail lesen',
      ChannelEventKind.whatsapp => 'WhatsApp lesen',
      ChannelEventKind.sms => 'SMS lesen',
    };
  }

  String _channelEventDescription(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email =>
        'Liest Absender, Betreff, Nachricht und Ankunftszeit aus einem E-Mail-Trigger.',
      ChannelEventKind.whatsapp =>
        'Liest Absender, Nachricht und Ankunftszeit aus einem WhatsApp-Trigger.',
      ChannelEventKind.sms =>
        'Liest Absender, Nachricht und Ankunftszeit aus einem SMS-Trigger.',
    };
  }

  String _sendMessageTitle(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email => 'E-Mail senden',
      ChannelEventKind.whatsapp => 'WhatsApp senden',
      ChannelEventKind.sms => 'SMS senden',
    };
  }

  String _sendMessageDescription(ChannelEventKind kind) {
    return switch (kind) {
      ChannelEventKind.email => 'Sendet eine E-Mail über novooa.',
      ChannelEventKind.whatsapp =>
        'Sendet eine WhatsApp-Nachricht über novooa.',
      ChannelEventKind.sms => 'Sendet eine SMS über novooa.',
    };
  }
}
