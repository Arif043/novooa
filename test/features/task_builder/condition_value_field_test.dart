import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cupertino_sidemenu/cupertino_sidemenu.dart';
import 'package:syscat2/core/theme/syscat_theme.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_editor.dart';
import 'package:syscat2/features/task_builder/domain/entities/workflow_graph.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/branch_condition_operand_type.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/condition_value_field.dart';

void main() {
  for (final source in [false, true]) {
    testWidgets('Wertart-Menü verschiebt die App nicht (Baustein=$source)', (
      tester,
    ) async {
      const pageKey = ValueKey('center-page');
      await tester.pumpWidget(
        MaterialApp(
          home: CupertinoSidemenu(
            hapticFeedback: false,
            menuWidthOfScreen: .28,
            leftMenu: const SizedBox(),
            centerPage: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  key: pageKey,
                  body: Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 300,
                      child: ConditionValueField(
                        value: source ? '{{legacy}}' : 'Text',
                        graph: const WorkflowGraph(nodes: [], edges: []),
                        label: 'Vergleichswert',
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = tester.getTopLeft(find.byKey(pageKey));
      await tester.tap(find.byTooltip('Art des Werts wählen'));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(pageKey)), before);
      await tester.tap(
        find.widgetWithText(
          PopupMenuItem<bool>,
          source ? 'Fester Wert' : 'Wert aus einem Baustein',
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byKey(pageKey)), before);
      expect(tester.takeException(), isNull);
    });
  }
  for (final dark in [false, true]) {
    testWidgets('Verschachtelte Gruppe bei schmaler Breite, dark=$dark', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: dark ? SyscatTheme.darkTheme : SyscatTheme.lightTheme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: SingleChildScrollView(
                  child: BranchConditionEditor(
                    condition: const GroupCondition(
                      combinator: BooleanCombinator.or,
                      children: [
                        GroupCondition(
                          combinator: BooleanCombinator.and,
                          children: [emptyComparisonCondition],
                        ),
                        emptyComparisonCondition,
                      ],
                    ),
                    graph: const WorkflowGraph(nodes: [], edges: []),
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.textContaining('{{'), findsNothing);
    });
  }
  Future<void> mount(
    WidgetTester tester, {
    String value = '',
    OperandTypeHint hint = const UnknownTypeHint(),
    required ValueChanged<String> onChanged,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: ConditionValueField(
                value: value,
                graph: const WorkflowGraph(nodes: [], edges: []),
                label: 'Vergleichswert',
                hint: hint,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('Schalter zeigt Ja/Nein und speichert booleschen Wert', (
    tester,
  ) async {
    String? selected;
    await mount(
      tester,
      hint: const BooleanTypeHint(),
      onChanged: (v) => selected = v,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ja').last);
    await tester.pumpAndSettle();
    expect(selected, 'true');
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('Auswahlwerte werden als Optionen angeboten', (tester) async {
    String? selected;
    await mount(
      tester,
      hint: const EnumTypeHint(['Offen', 'Erledigt']),
      onChanged: (v) => selected = v,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Erledigt').last);
    await tester.pumpAndSettle();
    expect(selected, 'Erledigt');
  });

  testWidgets('Bestehende Sonderausdrücke bleiben unverändert und verborgen', (
    tester,
  ) async {
    String? changed;
    await mount(
      tester,
      value: '{{legacy.field}}',
      onChanged: (v) => changed = v,
    );
    expect(find.textContaining('{{'), findsNothing);
    expect(
      find.text('Gespeicherter Ausdruck (nicht in der Auswahl)'),
      findsOneWidget,
    );
    expect(changed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Extern aktualisierte Literale ersetzen die Quellenauswahl', (
    tester,
  ) async {
    await mount(tester, value: '{{legacy}}', onChanged: (_) {});
    await mount(tester, value: 'Neuer Wert', onChanged: (_) {});
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Neuer Wert'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
