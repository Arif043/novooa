import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_suggestion.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/template_expression_text_field.dart';

void main() {
  testWidgets('fügt die Auswahl als gespeicherten Template-Ausdruck ein', (
    tester,
  ) async {
    var storedValue = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TemplateExpressionTextField(
            value: storedValue,
            suggestions: const [
              TemplateExpressionSuggestion(
                expression: '{{prompt1}}',
                label: 'Prompt · prompt1',
              ),
            ],
            onChanged: (value) => storedValue = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).first, 'Hallo #');
    await tester.pumpAndSettle();
    expect(find.text('Prompt · prompt1'), findsOneWidget);

    await tester.tap(find.text('Prompt · prompt1'));
    await tester.pumpAndSettle();

    expect(storedValue, 'Hallo {{prompt1}}');
    expect(find.text('prompt1'), findsOneWidget);
  });

  testWidgets(
    'blendet feste Nebenoutputs standardmäßig aus und erst über den Filter '
    '"Feste Felder" ein',
    (tester) async {
      var storedValue = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TemplateExpressionTextField(
              value: storedValue,
              suggestions: const [
                TemplateExpressionSuggestion(
                  expression: '{{speichern1}}',
                  label: 'Datensatz speichern · speichern1',
                ),
                TemplateExpressionSuggestion(
                  expression: '{{speichern1.created}}',
                  label: 'Datensatz speichern · speichern1.created',
                  kind: TemplateExpressionSuggestionKind.secondary,
                ),
              ],
              onChanged: (value) => storedValue = value,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField).first, '#');
      await tester.pumpAndSettle();

      expect(find.text('Datensatz speichern · speichern1'), findsOneWidget);
      expect(
        find.text('Datensatz speichern · speichern1.created'),
        findsNothing,
      );

      await tester.tap(find.text('Feste Felder'));
      await tester.pumpAndSettle();

      expect(
        find.text('Datensatz speichern · speichern1.created'),
        findsOneWidget,
      );

      await tester.tap(find.text('Datensatz speichern · speichern1.created'));
      await tester.pumpAndSettle();

      expect(storedValue, '{{speichern1.created}}');
    },
  );
}
