import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_runs.dart';
import 'package:syscat2/features/results/presentation/cubits/run_results_cubit.dart';
import 'package:syscat2/features/results/presentation/pages/results_page.dart';

import 'support/run_result_fixtures.dart';

Future<void> _pump(WidgetTester tester, List<TaskRun> runs, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  serviceLocator.registerFactory(
    () => RunResultsCubit(WatchTaskRuns(_Runs(Stream.value(runs)))),
  );
  addTearDown(() => serviceLocator.unregister<RunResultsCubit>());
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: const Scaffold(body: ResultsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  testWidgets('ohne Läufe lädt die Seite zu den Aufgaben ein', (tester) async {
    await _pump(tester, const [], const Size(1200, 900));

    expect(find.text('Noch keine Ergebnisse'), findsOneWidget);
    expect(find.text('Zu den Aufgaben'), findsOneWidget);
  });

  testWidgets('Läufe stehen als Zeilen mit Ergebnis, auch auf dem Handy', (
    tester,
  ) async {
    await _pump(tester, [testRun], const Size(390, 844));

    expect(tester.takeException(), isNull);
    expect(find.text('Rechnungen ablegen'), findsOneWidget);
    expect(find.text('Fertig · 4 s'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Erfolgreich')), findsOneWidget);
  });
}

class _Runs implements TaskRunRepository {
  _Runs(this.stream);

  final Stream<List<TaskRun>> stream;

  @override
  Stream<List<TaskRun>> watchRecent() => stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
