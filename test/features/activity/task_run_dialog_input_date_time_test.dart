import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/features/activity/domain/entities/task_run_dialog_input_field.dart';
import 'package:syscat2/features/activity/presentation/widgets/task_run_dialog_input_form.dart';

const _date = TaskRunDialogInputField(
  name: 'termin',
  type: TaskRunDialogInputFieldType.date,
  options: [],
);
const _time = TaskRunDialogInputField(
  name: 'uhrzeit',
  type: TaskRunDialogInputFieldType.time,
  options: [],
);

Future<GlobalKey<FormState>> _pumpForm(
  WidgetTester tester,
  Map<String, Object?> values,
) async {
  final formKey = GlobalKey<FormState>();
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: TaskRunDialogInputForm(
          formKey: formKey,
          fields: const [_date, _time],
          controllers: const {},
          values: values,
          onValueChanged: (name, value) => values[name] = value,
        ),
      ),
    ),
  );
  return formKey;
}

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  testWidgets('ohne Datum und Uhrzeit ist das Formular nicht vollständig', (
    tester,
  ) async {
    final formKey = await _pumpForm(tester, {});

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();

    expect(find.text('Bitte ein Datum wählen.'), findsOneWidget);
    expect(find.text('Bitte eine Uhrzeit wählen.'), findsOneWidget);
  });

  testWidgets(
    'ein gewähltes Datum aus dem Kalender wird als Tag gesendet',
    variant: TargetPlatformVariant.only(TargetPlatform.macOS),
    (tester) async {
      final values = <String, Object?>{};
      await _pumpForm(tester, values);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final now = DateTime.now();
      final month = now.month.toString().padLeft(2, '0');
      expect(values['termin'], '${now.year}-$month-15');
      expect(find.text('15.${now.month}.${now.year}'), findsOneWidget);
    },
  );

  testWidgets(
    'auf dem Handy wählt das Drehrad die Uhrzeit, gesendet als HH:mm',
    variant: TargetPlatformVariant.only(TargetPlatform.android),
    (tester) async {
      final values = <String, Object?>{'uhrzeit': '07:45'};
      await _pumpForm(tester, values);

      await tester.tap(find.byIcon(Icons.schedule_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(values['uhrzeit'], '07:45');
      expect(find.text('07:45'), findsOneWidget);
    },
  );

  testWidgets('vorhandene Werte stehen lesbar im Feld', (tester) async {
    final formKey = await _pumpForm(tester, {
      'termin': '2026-10-28',
      'uhrzeit': '09:30',
    });

    expect(find.text('28.10.2026'), findsOneWidget);
    expect(find.text('09:30'), findsOneWidget);
    expect(formKey.currentState!.validate(), isTrue);
  });
}
