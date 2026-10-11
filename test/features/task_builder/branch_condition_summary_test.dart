import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_summary.dart';

const _antwortIstJa = ComparisonCondition(
  left: '{{Antwort}}',
  operator: ComparisonOperator.equals,
  right: 'Ja',
);

void main() {
  test('ein Vergleich zeigt Wertname, Operator und festen Wert', () {
    expect(branchConditionSummary(_antwortIstJa), 'Antwort ist Ja');
  });

  test('ein Verweis rechts wird wie links ohne Klammern gezeigt', () {
    const condition = ComparisonCondition(
      left: '{{Summe}}',
      operator: ComparisonOperator.greaterThan,
      right: '{{Grenze}}',
    );

    expect(branchConditionSummary(condition), 'Summe größer als Grenze');
  });

  test('leere Operanden erscheinen als Auslassung', () {
    const condition = ComparisonCondition(
      left: '',
      operator: ComparisonOperator.equals,
      right: ' ',
    );

    expect(branchConditionSummary(condition), '… ist …');
  });

  test(
    'Gruppen werden mit Bindewort verbunden, verschachtelte in Klammern',
    () {
      const condition = GroupCondition(
        combinator: BooleanCombinator.and,
        children: [
          _antwortIstJa,
          GroupCondition(
            combinator: BooleanCombinator.or,
            children: [
              ComparisonCondition(
                left: '{{Land}}',
                operator: ComparisonOperator.contains,
                right: 'DE',
              ),
              ComparisonCondition(
                left: '{{Land}}',
                operator: ComparisonOperator.notEquals,
                right: 'AT',
              ),
            ],
          ),
        ],
      );

      expect(
        branchConditionSummary(condition),
        'Antwort ist Ja und (Land enthält DE oder Land ist nicht AT)',
      );
    },
  );

  test('ein Zweig ohne Bedingung heißt „Sonst“', () {
    expect(branchConditionSummary(null), 'Sonst');
  });
}
