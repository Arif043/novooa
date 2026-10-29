import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/results/domain/entities/run_result.dart';
import 'package:syscat2/features/results/domain/entities/run_result_failure.dart';
import 'package:syscat2/features/results/domain/repositories/run_result_repository.dart';
import 'package:syscat2/features/results/domain/usecases/load_run_result.dart';
import 'package:syscat2/features/results/presentation/cubits/run_result_cubit.dart';
import 'package:syscat2/features/results/presentation/pages/run_result_page.dart';

import 'support/run_result_fixtures.dart';

Future<void> _pump(WidgetTester tester, Size size, RunResult result) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  serviceLocator.registerFactory(
    () => RunResultCubit(LoadRunResult(_Repository(result))),
  );
  addTearDown(() => serviceLocator.unregister<RunResultCubit>());
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('de'),
      supportedLocales: const [Locale('de')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: RunResultPage(run: result.run),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  testWidgets('am Desktop: Ergebnis, Folgen und Graph; die Runde lässt sich '
      'wechseln', (tester) async {
    await _pump(tester, const Size(1400, 1000), testResult());

    expect(tester.takeException(), isNull);
    expect(find.text('Ergebnis'), findsOneWidget);
    expect(find.text('Fertig'), findsOneWidget);
    expect(find.text('Für jedes Element'), findsWidgets);
    expect(find.text('Runde 1 von 2'), findsOneWidget);
    expect(find.text('R-1'), findsOneWidget);

    await tester.tap(find.byTooltip('Nächste Runde'));
    await tester.pumpAndSettle();

    expect(find.text('Runde 2 von 2'), findsOneWidget);
    expect(find.text('R-2'), findsOneWidget);
  });

  testWidgets('der nicht genommene Zweig ist als nicht ausgeführt markiert', (
    tester,
  ) async {
    await _pump(tester, const Size(1400, 1000), testResult());

    expect(
      find.bySemanticsLabel(RegExp('Titel nein-text, Nicht ausgeführt')),
      findsOneWidget,
    );
  });

  testWidgets('auf dem Handy ohne Überlauf', (tester) async {
    await _pump(tester, const Size(390, 844), testResult());

    expect(tester.takeException(), isNull);
    expect(find.text('Ablauf'), findsOneWidget);
  });

  testWidgets('ein alter Lauf ohne Graph zeigt die Bausteine als Liste', (
    tester,
  ) async {
    final old = RunResult(run: testRun, graph: null, nodes: testResult().nodes);

    await _pump(tester, const Size(1400, 1000), old);

    expect(find.textContaining('keinen gespeicherten Graphen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _Repository implements RunResultRepository {
  _Repository(this.result);

  final RunResult result;

  @override
  Future<Result<RunResult, RunResultFailure>> load(TaskRun run) async =>
      Success(result);
}
