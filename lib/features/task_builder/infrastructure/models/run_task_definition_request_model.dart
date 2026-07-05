import '../../domain/entities/node_config.dart';
import '../../domain/entities/task.dart';
import '../../domain/entities/workflow_edge.dart';
import '../../domain/entities/workflow_graph.dart';
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
      'nodes': task.graph.nodes.map(_nodeToJson).toList(growable: false),
      'edges': task.graph.edges.map(_edgeToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _nodeToJson(WorkflowNode node) {
    return {
      'id': node.id.value,
      'primitive': _primitiveToJson(node.config.primitive),
      'title': node.title,
      'description': node.description,
      'config': _configToJson(node.config),
    };
  }

  Map<String, Object?> _configToJson(NodeConfig config) {
    return switch (config) {
      PromptNodeConfig() => _promptToJson(config),
      ConditionalNodeConfig() => _conditionalToJson(config),
      IterativeRefinementNodeConfig() => _iterativeRefinementToJson(config),
    };
  }

  Map<String, Object?> _promptToJson(PromptNodeConfig config) {
    return {
      'primitive': config.primitive.name,
      'instruction': config.instruction,
      'outputType': config.outputType.name,
      'choices': config.choices,
    };
  }

  Map<String, Object?> _conditionalToJson(ConditionalNodeConfig config) {
    return {
      'primitive': _primitiveToJson(config.primitive),
      'choices': config.choices,
      'branches': config.branches.map(_branchToJson).toList(growable: false),
    };
  }

  Map<String, Object?> _iterativeRefinementToJson(
    IterativeRefinementNodeConfig config,
  ) {
    return {
      'primitive': config.primitive.name,
      'critiquePrompt': config.critiquePrompt,
      'maxIterations': config.maxIterations,
      'graph': _graphToJson(config.graph),
    };
  }

  Map<String, Object?> _branchToJson(ConditionalBranch branch) {
    return {
      'id': branch.id,
      'label': branch.label,
      'graph': {..._graphToJson(branch.graph)},
    };
  }

  Map<String, Object?> _graphToJson(WorkflowGraph graph) {
    return {
      'nodes': graph.nodes.map(_nodeToJson).toList(growable: false),
      'edges': graph.edges.map(_edgeToJson).toList(growable: false),
    };
  }

  String _primitiveToJson(WorkflowPrimitive primitive) {
    return switch (primitive) {
      WorkflowPrimitive.conditional => 'conditionalFlow',
      _ => primitive.name,
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
