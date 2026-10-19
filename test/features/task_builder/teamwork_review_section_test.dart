import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/task_builder/domain/entities/node_config.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/node_language_model_field.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/teamwork/teamwork_review_section.dart';

void main() {
  Future<List<TeamworkReview>> pump(
    WidgetTester tester,
    TeamworkReview review,
  ) async {
    final changes = <TeamworkReview>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TeamworkReviewSection(
              review: review,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('mit Prüfung gibt es eine eigene Modellwahl', (tester) async {
    await pump(tester, const TeamworkReview());

    expect(find.text('Modell der Prüfung'), findsOneWidget);
    expect(find.byType(NodeLanguageModelField), findsOneWidget);
  });

  testWidgets('ohne Prüfung verschwindet die Modellwahl', (tester) async {
    await pump(tester, const TeamworkReview(enabled: false));

    expect(find.byType(NodeLanguageModelField), findsNothing);
  });

  testWidgets('der Schalter schaltet die Prüfung ab und behält das Modell', (
    tester,
  ) async {
    final changes = await pump(
      tester,
      const TeamworkReview(languageModelId: 'stark'),
    );

    await tester.tap(find.byType(Switch));

    expect(
      changes.single,
      const TeamworkReview(enabled: false, languageModelId: 'stark'),
    );
  });
}
