import 'workflow_node.dart';

/// Gerichtete Verbindung zwischen zwei [WorkflowNode]-Instanzen.
///
/// [conditionLabel] ist nur für verzweigende Primitives wie
/// [WorkflowPrimitive.conditionalFlow] relevant und beschreibt die
/// Bedingung, unter der dieser Pfad gewählt wird. Bei sequentiellen Kanten
/// bleibt er `null`.
///
/// Invariante: `from` und `to` müssen auf existierende Knoten zeigen — die
/// Verantwortung liegt im [TaskDefinition] (siehe `removeNode`).
class WorkflowEdge {
  const WorkflowEdge({
    required this.from,
    required this.to,
    this.conditionLabel,
  });

  final NodeId from;
  final NodeId to;
  final String? conditionLabel;
}