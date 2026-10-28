import 'package:get_it/get_it.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../features/activity/domain/usecases/watch_task_runs.dart';
import '../../features/results/domain/repositories/run_result_repository.dart';
import '../../features/results/domain/usecases/load_run_result.dart';
import '../../features/results/infrastructure/local_run_result_repository.dart';
import '../../features/results/presentation/cubits/run_result_cubit.dart';
import '../../features/results/presentation/cubits/run_results_cubit.dart';

/// „Ergebnisse“: Lauf-Liste und Ergebnisansicht eines Laufs.
void configureStandaloneResultsDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<RunResultRepository>(
      () => LocalRunResultRepository(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton(() => LoadRunResult(locator<RunResultRepository>()))
    ..registerFactory(() => RunResultsCubit(locator<WatchTaskRuns>()))
    ..registerFactory(() => RunResultCubit(locator<LoadRunResult>()));
}
