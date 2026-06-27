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
    required this.output,
    this.selectedNodeId,
    this.message,
  });

  final String nodeId;
  final String primitive;
  final String status;
  final String output;
  final String? selectedNodeId;
  final String? message;

  factory NodeExecutionResultModel.fromJson(Map<dynamic, dynamic> json) {
    return NodeExecutionResultModel(
      nodeId: json['nodeId'] as String? ?? '',
      primitive: json['primitive'] as String? ?? 'prompt',
      status: json['status'] as String? ?? 'skipped',
      output: json['output'] as String? ?? '',
      selectedNodeId: json['selectedNodeId'] as String?,
      message: json['message'] as String?,
    );
  }

  NodeExecutionResult toDomain() {
    return NodeExecutionResult(
      nodeId: NodeId(nodeId),
      primitive: _primitiveFromName(primitive),
      status: NodeExecutionStatus.fromName(status),
      output: output,
      selectedNodeId: selectedNodeId == null ? null : NodeId(selectedNodeId!),
      message: message,
    );
  }

  WorkflowPrimitive _primitiveFromName(String name) {
    return WorkflowPrimitive.values.firstWhere(
      (primitive) => primitive.name == name,
      orElse: () => WorkflowPrimitive.prompt,
    );
  }
}
