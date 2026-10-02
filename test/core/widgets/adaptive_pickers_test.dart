import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/widgets/adaptive_pickers.dart';

Future<BuildContext> _pumpHost(WidgetTester tester) async {
  late BuildContext captured;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Builder(
        builder: (context) {
          captured = context;
          return const Scaffold(body: SizedBox());
        },
      ),
    ),
  );
  return captured;
}

final _initial = DateTime(2026, 10, 15);
final _min = DateTime(2026, 10, 1);
final _max = DateTime(2027, 10, 1);

void main() {
  group('Mobil: Bottom Sheet mit Drehrad', () {
    final mobile = TargetPlatformVariant.only(TargetPlatform.android);

    testWidgets('Datum: Fertig liefert die Auswahl', (tester) async {
      final context = await _pumpHost(tester);
      DateTime? result;
      showAdaptiveDatePicker(
        context: context,
        initialDate: _initial,
        minimumDate: _min,
        maximumDate: _max,
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.text('Datum'), findsOneWidget);

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(result, _initial);
    }, variant: mobile);

    testWidgets('Datum: Abbrechen liefert nichts', (tester) async {
      final context = await _pumpHost(tester);
      var done = false;
      DateTime? result = _initial;
      showAdaptiveDatePicker(
        context: context,
        initialDate: _initial,
        minimumDate: _min,
        maximumDate: _max,
      ).then((value) {
        result = value;
        done = true;
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(result, isNull);
    }, variant: mobile);

    testWidgets('Uhrzeit: Fertig liefert die Auswahl', (tester) async {
      final context = await _pumpHost(tester);
      TimeOfDay? result;
      showAdaptiveTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 9, minute: 30),
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Uhrzeit'), findsOneWidget);

      await tester.tap(find.text('Fertig'));
      await tester.pumpAndSettle();

      expect(result, const TimeOfDay(hour: 9, minute: 30));
    }, variant: mobile);
  });

  group('Desktop: übliche Material-Dialoge', () {
    final desktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    testWidgets('Datum: Kalender-Dialog, Bestätigen liefert das Datum', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      DateTime? result;
      showAdaptiveDatePicker(
        context: context,
        initialDate: _initial,
        minimumDate: _min,
        maximumDate: _max,
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Abbrechen'), findsOneWidget, reason: 'deutsch');

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, _initial);
    }, variant: desktop);

    testWidgets('Datum: Abbrechen liefert nichts', (tester) async {
      final context = await _pumpHost(tester);
      var done = false;
      DateTime? result = _initial;
      showAdaptiveDatePicker(
        context: context,
        initialDate: _initial,
        minimumDate: _min,
        maximumDate: _max,
      ).then((value) {
        result = value;
        done = true;
      });
      await tester.pumpAndSettle();

      await tester.tap(find.text('Abbrechen'));
      await tester.pumpAndSettle();

      expect(done, isTrue);
      expect(result, isNull);
    }, variant: desktop);

    testWidgets('Uhrzeit: Zeit-Dialog statt Bottom Sheet', (tester) async {
      final context = await _pumpHost(tester);
      TimeOfDay? result;
      showAdaptiveTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 14, minute: 5),
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerDialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, const TimeOfDay(hour: 14, minute: 5));
    }, variant: desktop);

    testWidgets('ein Startdatum außerhalb des Bereichs wird eingegrenzt', (
      tester,
    ) async {
      final context = await _pumpHost(tester);
      DateTime? result;
      showAdaptiveDatePicker(
        context: context,
        initialDate: DateTime(2020),
        minimumDate: _min,
        maximumDate: _max,
      ).then((value) => result = value);
      await tester.pumpAndSettle();

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, _min);
    }, variant: desktop);
  });
}
