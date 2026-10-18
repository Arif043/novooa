import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'condition_value_sources.dart';

/// Ein im Editor auswählbarer Verweis. Gespeichert wird ausschließlich
/// [expression]; [label] dient nur der Darstellung.
class TemplateExpressionSuggestion {
  const TemplateExpressionSuggestion({
    required this.expression,
    required this.label,
  });

  final String expression;
  final String label;
}

List<TemplateExpressionSuggestion> templateExpressionSuggestions({
  required WorkflowGraph graph,
  required NodeId targetNodeId,
}) {
  final sourceGraph = conditionSourceGraph(graph, targetNodeId);
  final outputSources = conditionValueSources(sourceGraph);
  final suggestions = <TemplateExpressionSuggestion>[
    for (final entry in outputSources.entries)
      TemplateExpressionSuggestion(expression: entry.key, label: entry.value),
  ];
  final unique = <String, TemplateExpressionSuggestion>{};
  for (final suggestion in suggestions) {
    unique.putIfAbsent(suggestion.expression, () => suggestion);
  }
  return unique.values.toList(growable: false);
}
