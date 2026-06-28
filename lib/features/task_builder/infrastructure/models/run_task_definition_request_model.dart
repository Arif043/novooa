import '../../domain/entities/node_config.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_node.dart';

class RunTaskDefinitionRequestModel {
  const RunTaskDefinitionRequestModel({
    required this.taskDefinition,
    required this.context,
  });

  final Task taskDefinition;
  final String context;

  Map<String, Object?> toJson() {
    return {'taskDefinition': _taskToJson(taskDefinition), 'context': context};
  }

  Map<String, Object?> _taskToJson(Task task) {
    return {
      'id': task.id,
      'title': task.title,
      'objective': task.objective,
      'nodes': task.nodes.map(_nodeToJson).toList(growable: false),
      'edges': task.edges.map(_edgeToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _nodeToJson(WorkflowNode node) {
    return {
      'id': node.id.value,
      'primitive': node.config.primitive.name,
      'title': node.title,
      'description': node.description,
      'config': _configToJson(node.config),
    };
  }

  Map<String, Object?> _configToJson(NodeConfig config) {
    return switch (config) {
      PromptNodeConfig() => _promptToJson(config),
      ConditionalNodeConfig() => throw UnimplementedError(),
    };
  }

  Map<String, Object?> _promptToJson(PromptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'outputType': config.outputType.name,
      'firstChoice': config.firstChoice,
      'secondChoice': config.secondChoice,
    };
  }

  Map<String, Object?> _edgeToJson(WorkflowEdge edge) {
    return {
      'from': edge.from.value,
      'to': edge.to.value,
      if (edge.conditionLabel != null) 'conditionLabel': edge.conditionLabel,
    };
  }
}
