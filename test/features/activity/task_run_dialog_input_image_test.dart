import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_dialog_input_field.dart';
import 'package:syscat2/features/activity/presentation/widgets/task_run_dialog_input_form.dart';

const _receipt = TaskRunDialogInputField(
  name: 'beleg',
  type: TaskRunDialogInputFieldType.image,
  options: [],
);

Future<GlobalKey<FormState>> _pumpForm(WidgetTester tester) async {
  final formKey = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TaskRunDialogInputForm(
          formKey: formKey,
          fields: const [_receipt],
          controllers: const {},
          values: const {},
          onValueChanged: (_, _) {},
        ),
      ),
    ),
  );
  return formKey;
}

void main() {
  testWidgets('auf dem Handy bietet das Bildfeld auch „Dokument scannen“ an', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await _pumpForm(tester);

    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Bild auswählen'), findsOneWidget);
    expect(find.text('Dokument scannen'), findsOneWidget);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ohne Scanner auf dem Desktop fehlt „Dokument scannen“', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    await _pumpForm(tester);

    expect(find.text('Kamera'), findsOneWidget);
    expect(find.text('Dokument scannen'), findsNothing);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('ohne Bild ist das Formular nicht vollständig', (tester) async {
    final formKey = await _pumpForm(tester);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Bitte füge ein Bild hinzu.'), findsOneWidget);
  });
}
