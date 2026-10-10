import 'package:easy_localization/easy_localization.dart';
import 'package:syscat2/core/localization/locale_keys.g.dart';
import '../../domain/entities/node_config.dart';
import '../../domain/entities/workflow_graph.dart';
import '../../domain/entities/workflow_node.dart';
import 'condition_value_sources.dart';

/// Ob ein Vorschlag ein Ausgabewert oder eine Script-Variable ist.
enum TemplateExpressionSuggestionKind { primary, variable }

/// Ein im Editor auswählbarer Verweis. Gespeichert wird ausschließlich
/// [expression]; [label] dient nur der Darstellung.
class TemplateExpressionSuggestion {
  const TemplateExpressionSuggestion({
    required this.expression,
    required this.label,
    this.kind = TemplateExpressionSuggestionKind.primary,
  });

  final String expression;
  final String label;
  final TemplateExpressionSuggestionKind kind;
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
  for (final node in sourceGraph.nodes) {
    if (node.config case ScriptNodeConfig(:final script)) {
      for (final variable in _scriptVariables(script)) {
        suggestions.add(
          TemplateExpressionSuggestion(
            expression: '{{$variable}}',
            label: LocaleKeys.ui_node_variable.tr(
              namedArgs: {'node': node.title, 'name': variable},
            ),
            kind: TemplateExpressionSuggestionKind.variable,
          ),
        );
      }
    }
  }
  final unique = <String, TemplateExpressionSuggestion>{};
  for (final suggestion in suggestions) {
    unique.putIfAbsent(suggestion.expression, () => suggestion);
  }
  return unique.values.toList(growable: false);
}

Iterable<String> _scriptVariables(String script) sync* {
  final assignments = RegExp(
    r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=(?!=)',
    multiLine: true,
  );
  const reserved = {'input', 'output', 'files'};
  for (final match in assignments.allMatches(script)) {
    final name = match.group(1)!;
    if (!reserved.contains(name)) yield name;
  }
}
