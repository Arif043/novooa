import '../../domain/entities/task_execution_result.dart';
import '../../domain/entities/workflow_node.dart';

class TaskExecutionResultModel {
  const TaskExecutionResultModel({
    required this.taskId,
    required this.finalOutput,
    required this.nodeResults,
  });

  final String taskId;
  final String finalOutput;
  final List<NodeExecutionResultModel> nodeResults;

  factory TaskExecutionResultModel.fromJson(Map<String, Object?> json) {
    final rawResults = json['nodeResults'] as List<Object?>? ?? [];
    return TaskExecutionResultModel(
      taskId: json['taskId'] as String? ?? '',
      finalOutput: json['finalOutput'] as String? ?? '',
      nodeResults: rawResults
          .map((item) => NodeExecutionResultModel.fromJson(item as Map))
          .toList(growable: false),
    );
  }

  TaskExecutionResult toDomain() {
    return TaskExecutionResult(
      taskId: taskId,
      finalOutput: finalOutput,
      nodeResults: nodeResults.map((model) => model.toDomain()).toList(),
    );
  }
}

class NodeExecutionResultModel {
  const NodeExecutionResultModel({
    required this.nodeId,
    required this.primitive,
    required this.status,
    this.outputs = const {},
    this.selectedNodeId,
    this.message,
  });

  final String nodeId;
  final String primitive;
  final String status;
  final Map<String, NodeOutputValueModel> outputs;
  final String? selectedNodeId;
  final String? message;

  factory NodeExecutionResultModel.fromJson(Map<dynamic, dynamic> json) {
    return NodeExecutionResultModel(
      nodeId: json['nodeId'] as String? ?? '',
      primitive: json['primitive'] as String? ?? 'prompt',
      status: json['status'] as String? ?? 'skipped',
      outputs: _outputsFrom(json['outputs']),
      selectedNodeId: json['selectedNodeId'] as String?,
      message: json['message'] as String?,
    );
  }

  NodeExecutionResult toDomain() {
    return NodeExecutionResult(
      nodeId: NodeId(nodeId),
      primitive: _primitiveFromName(primitive),
      status: NodeExecutionStatus.fromName(status),
      outputs: outputs.map((key, value) => MapEntry(key, value.toDomain())),
      selectedNodeId: selectedNodeId == null ? null : NodeId(selectedNodeId!),
      message: message,
    );
  }

  static Map<String, NodeOutputValueModel> _outputsFrom(Object? value) {
    if (value is! Map) return const {};
    return value.map((key, item) {
      final model = item is Map
          ? NodeOutputValueModel.fromJson(item)
          : NodeOutputValueModel(type: 'json', value: item);
      return MapEntry(key.toString(), model);
    });
  }

  WorkflowPrimitive _primitiveFromName(String name) {
    return WorkflowPrimitive.values.firstWhere(
      (primitive) => primitive.name == name,
      orElse: () => WorkflowPrimitive.prompt,
    );
  }
}

class NodeOutputValueModel {
  const NodeOutputValueModel({required this.type, required this.value});

  final String type;
  final Object? value;

  factory NodeOutputValueModel.fromJson(Map<dynamic, dynamic> json) {
    return NodeOutputValueModel(
      type: json['type'] as String? ?? 'json',
      value: json['value'],
    );
  }

  NodeOutputValue toDomain() {
    return NodeOutputValue(type: NodeOutputType.fromName(type), value: value);
  }
}
