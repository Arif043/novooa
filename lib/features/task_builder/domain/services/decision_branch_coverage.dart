import '../entities/node_config.dart';
import '../entities/workflow_graph.dart';

/// Die Antworten eines Entscheidungs-Prompts, für die der Bedingte Ablauf
/// keinen Zweig `{{valueName}}` *ist gleich* `<Antwort>` hat. Leere
/// Antworten zählen nicht; „Sonst“ und andere Bedingungen decken nichts ab.
List<String> missingDecisionAnswers(
  ConditionalNodeConfig config,
  String valueName,
  List<String> choices,
) {
  final covered = {
    for (final branch in config.branches)
      ?_answerOf(branch.condition, valueName),
  };
  final missing = <String>[];
  for (final choice in choices.map((choice) => choice.trim())) {
    if (choice.isNotEmpty && !covered.contains(choice)) {
      if (!missing.contains(choice)) missing.add(choice);
    }
  }
  return missing;
}

/// Ein Zweig, der genau eine Antwort abdeckt.
ConditionalBranch decisionBranchFor({
  required String id,
  required String answer,
  required String valueName,
}) {
  return ConditionalBranch(
    id: id,
    label: answer,
    graph: const WorkflowGraph(nodes: [], edges: []),
    condition: ComparisonCondition(
      left: _expressionFor(valueName),
      operator: ComparisonOperator.equals,
      right: answer,
    ),
  );
}

/// Ersetzt `{{from}}` durch `{{to}}` in allen Bedingungen, auch in Gruppen —
/// damit Bedingungen gültig bleiben, wenn der Wert umbenannt wird.
ConditionalNodeConfig withRenamedOperand(
  ConditionalNodeConfig config,
  String from,
  String to,
) {
  return config.copyWith(
    branches: [
      for (final branch in config.branches)
        branch.condition == null
            ? branch
            : branch.copyWith(
                condition: _renamed(branch.condition!, from, to),
              ),
    ],
  );
}

String? _answerOf(BranchCondition? condition, String valueName) {
  if (condition case ComparisonCondition(
    :final left,
    operator: ComparisonOperator.equals,
    :final right,
  ) when left.trim() == _expressionFor(valueName)) {
    return right.trim();
  }
  return null;
}

BranchCondition _renamed(BranchCondition condition, String from, String to) {
  String rename(String operand) =>
      operand.replaceAll(_expressionFor(from), _expressionFor(to));
  return switch (condition) {
    ComparisonCondition() => condition.copyWith(
      left: rename(condition.left),
      right: rename(condition.right),
    ),
    GroupCondition() => condition.copyWith(
      children: [
        for (final child in condition.children) _renamed(child, from, to),
      ],
    ),
  };
}

String _expressionFor(String valueName) => '{{$valueName}}';
