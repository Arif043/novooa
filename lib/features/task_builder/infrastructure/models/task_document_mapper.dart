import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/node_config.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'node_config_document_mapper.dart';

class TaskDocumentMapper {
  TaskDocumentMapper()
    : _configMapper = NodeConfigDocumentMapper(
        graphToDocument: _graphToDocumentStatic,
        graphFromDocument: _graphFromDocumentStatic,
      );

  final NodeConfigDocumentMapper _configMapper;

  Map<String, Object?> toDocument(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'objective': task.objective,
      'selectedNodeId': task.selectedNodeId.value,
      'graph': _graphToDocument(task.graph),
    };
  }

  Task fromDocument(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? {};
    return fromMap(data, fallbackId: snapshot.id);
  }

  Task fromMap(Map<String, Object?> data, {required String fallbackId}) {
    return Task(
      id: data['id'] as String? ?? fallbackId,
      title: data['title'] as String? ?? 'Unbenannte Aufgabe',
      objective: data['objective'] as String? ?? '',
      graph: _graphFromDocument(data['graph']),
      selectedNodeId: NodeId(data['selectedNodeId'] as String? ?? ''),
    );
  }

  Map<String, Object?> _graphToDocument(WorkflowGraph graph) {
    return {
      'nodes': graph.nodes.map(_nodeToDocument).toList(growable: false),
      'edges': graph.edges.map(_edgeToDocument).toList(growable: false),
    };
  }

  WorkflowGraph _graphFromDocument(Object? data) {
    if (data is! Map) return WorkflowGraph.empty();
    final map = _objectMapFrom(data);
    final nodes = _uniqueNodes(
      _mapListFrom(map['nodes']).map(_nodeFromDocument).toList(),
    );
    final nodeIds = nodes.map((node) => node.id).toSet();
    return WorkflowGraph(
      nodes: nodes,
      edges: _mapListFrom(map['edges'])
          .map(_edgeFromDocument)
          .where(
            (edge) => nodeIds.contains(edge.from) && nodeIds.contains(edge.to),
          )
          .toList(),
    );
  }

  List<WorkflowNode> _uniqueNodes(List<WorkflowNode> nodes) {
    final nodeIds = <NodeId>{};
    return nodes.where((node) => nodeIds.add(node.id)).toList();
  }

  Map<String, Object?> _nodeToDocument(WorkflowNode node) {
    return {
      'id': node.id.value,
      'title': node.title,
      'description': node.description,
      'outputName': node.outputName,
      if (node.outputFieldNames.isNotEmpty)
        'outputFieldNames': node.outputFieldNames,
      'config': _configMapper.toDocument(node.config),
    };
  }

  /// Erzwingt [WorkflowPrimitive.hasNoOutput] auch für Bestandsdaten: Wurde
  /// ein Knoten angelegt, bevor diese Regel für seine Primitive galt (oder
  /// per „Aufgabe duplizieren" aus einem solchen Knoten kopiert), trägt er
  /// sonst dauerhaft einen veralteten Ausgabenamen — ohne dass ihn je
  /// jemand explizit vergeben hätte. Selbstheilend beim nächsten Laden,
  /// statt eine einmalige Migration über den gesamten Datenbestand zu
  /// brauchen.
  WorkflowNode _nodeFromDocument(Map<String, Object?> data) {
    final config = _configFrom(data['config']);
    final outputName = config.primitive.hasNoOutput
        ? ''
        : data['outputName'] as String? ?? '';
    return WorkflowNode(
      id: NodeId(data['id'] as String? ?? ''),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      outputName: outputName,
      outputFieldNames: _outputFieldNamesFrom(data['outputFieldNames']),
      config: config,
    );
  }

  Map<String, String> _outputFieldNamesFrom(Object? value) {
    if (value is! Map) return const {};
    return {
      for (final MapEntry(:key, :value) in value.entries)
        if (key is String && value is String && value.trim().isNotEmpty)
          key: value.trim(),
    };
  }

  Map<String, Object?> _edgeToDocument(WorkflowEdge edge) {
    return {
      'from': edge.from.value,
      'to': edge.to.value,
      if (edge.conditionLabel != null) 'conditionLabel': edge.conditionLabel,
    };
  }

  WorkflowEdge _edgeFromDocument(Map<String, Object?> data) {
    return WorkflowEdge(
      from: NodeId(data['from'] as String? ?? ''),
      to: NodeId(data['to'] as String? ?? ''),
      conditionLabel: data['conditionLabel'] as String?,
    );
  }

  NodeConfig _configFrom(Object? value) {
    if (value is! Map) return StringInputNodeConfig.initial();
    return _configMapper.fromDocument(_objectMapFrom(value));
  }

  static Map<String, Object?> _graphToDocumentStatic(WorkflowGraph graph) {
    return TaskDocumentMapper()._graphToDocument(graph);
  }

  static WorkflowGraph _graphFromDocumentStatic(Object? data) {
    return TaskDocumentMapper()._graphFromDocument(data);
  }

  List<Map<String, Object?>> _mapListFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_objectMapFrom).toList(growable: false);
  }

  static Map<String, Object?> _objectMapFrom(Map<dynamic, dynamic> data) {
    return data.map((key, value) => MapEntry(key.toString(), value));
  }
}
