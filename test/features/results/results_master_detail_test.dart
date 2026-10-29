import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/di/service_locator.dart';
import 'package:syscat2/features/activity/domain/entities/task_run.dart';
import 'package:syscat2/features/activity/domain/repositories/task_run_repository.dart';
import 'package:syscat2/features/activity/domain/usecases/watch_task_runs.dart';
import 'package:syscat2/features/results/domain/entities/run_result.dart';
import 'package:syscat2/features/results/domain/entities/run_result_failure.dart';
import 'package:syscat2/features/results/domain/repositories/run_result_repository.dart';
import 'package:syscat2/features/results/domain/usecases/load_run_result.dart';
import 'package:syscat2/features/results/presentation/cubits/run_result_cubit.dart';
import 'package:syscat2/features/results/presentation/cubits/run_results_cubit.dart';
import 'package:syscat2/features/results/presentation/pages/results_page.dart';

import 'support/run_result_fixtures.dart';

void main() {
  setUpAll(() => initializeDateFormatting('de'));

  testWidgets('am Desktop steht der neueste Lauf gleich neben der Liste', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1500, 950);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    serviceLocator
      ..registerFactory(() => RunResultsCubit(WatchTaskRuns(_Runs())))
      ..registerFactory(() => RunResultCubit(LoadRunResult(_Results())));
    addTearDown(serviceLocator.reset);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        supportedLocales: const [Locale('de')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const Scaffold(body: ResultsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Rechnungen ablegen'), findsNWidgets(2));
    expect(find.text('Ablauf'), findsOneWidget);
    expect(find.text('Folgen'), findsOneWidget);
  });
}

class _Runs implements TaskRunRepository {
  @override
  Stream<List<TaskRun>> watchRecent() => Stream.value([testRun]);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Results implements RunResultRepository {
  @override
  Future<Result<RunResult, RunResultFailure>> load(TaskRun run) async =>
      Success(testResult());
}
