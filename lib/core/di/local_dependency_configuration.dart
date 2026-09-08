import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';

import '../../features/activity/domain/repositories/media_input_picker.dart';
import '../../features/activity/domain/repositories/task_activity_repository.dart';
import '../../features/activity/domain/repositories/task_run_media_input_repository.dart';
import '../../features/activity/domain/repositories/task_run_repository.dart';
import '../../features/activity/domain/usecases/review_task_run.dart';
import '../../features/activity/domain/usecases/upload_task_run_media_input.dart';
import '../../features/activity/domain/usecases/watch_task_activities.dart';
import '../../features/activity/domain/usecases/watch_task_runs.dart';
import '../../features/activity/infrastructure/datasources/image_picker_media_input_picker.dart';
import '../../features/activity/infrastructure/repositories/local_task_activity_repository.dart';
import '../../features/activity/infrastructure/repositories/local_task_run_repository.dart';
import '../../features/activity/infrastructure/repositories/unavailable_local_task_run_media_input_repository.dart';
import '../../features/activity/presentation/cubits/activity_cubit.dart';
import '../../features/task_builder/domain/repositories/task_repository.dart';
import '../../features/task_builder/domain/usecases/execute_task.dart';
import '../../features/task_builder/infrastructure/datasources/local_http_task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/repositories/local_task_repository.dart';
import '../../features/task_builder/presentation/cubits/task_builder_cubit.dart';
import '../../features/task_builder/presentation/cubits/task_homepage_cubit.dart';
import '../config/runtime_profile.dart';
import '../network/local_runtime_api_client.dart';

void configureLocalDependencies(GetIt locator, RuntimeProfile profile) {
  locator
    ..registerLazySingleton<LocalRuntimeApiClient>(
      () => HttpLocalRuntimeApiClient(baseUri: profile.localRuntimeUri),
    )
    ..registerLazySingleton<TaskRunnerDatasource>(
      () => LocalHttpTaskRunnerDatasource(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<TaskRepository>(
      () => LocalTaskRepository(
        locator<LocalRuntimeApiClient>(),
        locator<TaskRunnerDatasource>(),
      ),
    )
    ..registerLazySingleton<TaskRunRepository>(
      () => LocalTaskRunRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<TaskActivityRepository>(
      () => LocalTaskActivityRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<TaskRunMediaInputRepository>(
      UnavailableLocalTaskRunMediaInputRepository.new,
    )
    ..registerLazySingleton<MediaInputPicker>(
      () => ImagePickerMediaInputPicker(ImagePicker()),
    )
    ..registerLazySingleton(() => ExecuteTask(locator<TaskRepository>()))
    ..registerLazySingleton(() => WatchTaskRuns(locator<TaskRunRepository>()))
    ..registerLazySingleton(
      () => WatchTaskActivities(locator<TaskActivityRepository>()),
    )
    ..registerLazySingleton(() => ReviewTaskRun(locator<TaskRunRepository>()))
    ..registerLazySingleton(
      () => UploadTaskRunMediaInput(locator<TaskRunMediaInputRepository>()),
    )
    ..registerFactory(
      () =>
          TaskHomepageCubit(locator<TaskRepository>(), locator<ExecuteTask>()),
    )
    ..registerFactory(
      () => TaskBuilderCubit(repository: locator<TaskRepository>()),
    )
    ..registerFactory(
      () => ActivityCubit(
        watchTaskActivities: locator<WatchTaskActivities>(),
        watchTaskRuns: locator<WatchTaskRuns>(),
        reviewTaskRun: locator<ReviewTaskRun>(),
        mediaInputPicker: locator<MediaInputPicker>(),
        uploadTaskRunMediaInput: locator<UploadTaskRunMediaInput>(),
      ),
    );
}
