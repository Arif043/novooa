import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/domain/services/decision_branch_coverage.dart';

const _sonst = ConditionalBranch(
  id: 'branch.sonst',
  label: 'Sonst',
  graph: WorkflowGraph(nodes: [], edges: []),
);

ConditionalNodeConfig _config(List<ConditionalBranch> branches) =>
    ConditionalNodeConfig(branches: branches);

void main() {
  test('meldet nur Antworten ohne passenden „ist gleich“-Zweig', () {
    final config = _config([
      decisionBranchFor(id: 'b1', answer: 'Ja', valueName: 'Antwort'),
      const ConditionalBranch(
        id: 'b2',
        label: 'Nein',
        graph: WorkflowGraph(nodes: [], edges: []),
        condition: ComparisonCondition(
          left: '{{Antwort}}',
          operator: ComparisonOperator.contains,
          right: 'Nein',
        ),
      ),
      _sonst,
    ]);

    expect(
      missingDecisionAnswers(config, 'Antwort', ['Ja', 'Nein', '', 'Ja']),
      ['Nein'],
    );
  });

  test('ein Zweig auf einen anderen Wert deckt keine Antwort ab', () {
    final config = _config([
      decisionBranchFor(id: 'b1', answer: 'Ja', valueName: 'Antwort2'),
    ]);

    expect(missingDecisionAnswers(config, 'Antwort', ['Ja']), ['Ja']);
  });

  test('ein neuer Zweig vergleicht den Wert mit der Antwort', () {
    final branch = decisionBranchFor(
      id: 'b1',
      answer: 'Ja',
      valueName: 'Antwort',
    );

    expect(branch.label, 'Ja');
    expect(
      branch.condition,
      const ComparisonCondition(
        left: '{{Antwort}}',
        operator: ComparisonOperator.equals,
        right: 'Ja',
      ),
    );
  });

  test('benennt den Wert in allen Bedingungen um, auch in Gruppen; „Sonst“ '
      'bleibt', () {
    final config = _config([
      const ConditionalBranch(
        id: 'b1',
        label: 'Gruppe',
        graph: WorkflowGraph(nodes: [], edges: []),
        condition: GroupCondition(
          combinator: BooleanCombinator.and,
          children: [
            ComparisonCondition(
              left: '{{Antwort}}',
              operator: ComparisonOperator.equals,
              right: '{{Antwort}}-Kopie',
            ),
          ],
        ),
      ),
      _sonst,
    ]);

    final renamed = withRenamedOperand(config, 'Antwort', 'Text');

    final group = renamed.branches.first.condition! as GroupCondition;
    expect(
      group.children.single,
      const ComparisonCondition(
        left: '{{Text}}',
        operator: ComparisonOperator.equals,
        right: '{{Text}}-Kopie',
      ),
    );
    expect(renamed.branches.last, _sonst);
  });
}
