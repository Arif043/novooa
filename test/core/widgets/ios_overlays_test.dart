import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/ios_overlays.dart';

void main() {
  testWidgets('stellt Material für Formfelder in Cupertino-Dialogen bereit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showIosDialog<void>(
                context: context,
                builder: (_) => const CupertinoAlertDialog(
                  content: TextField(
                    decoration: InputDecoration(labelText: 'Antwort'),
                  ),
                ),
              ),
              child: const Text('Dialog öffnen'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Dialog öffnen'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
