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
import '../../features/application_logs/domain/repositories/application_log_repository.dart';
import '../../features/application_logs/domain/usecases/watch_application_logs.dart';
import '../../features/application_logs/infrastructure/repositories/local_application_log_repository.dart';
import '../../features/application_logs/presentation/cubits/application_logs_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/infrastructure/repositories/local_workspace_auth_repository.dart';
import '../../features/files/domain/usecases/watch_team_files.dart';
import '../../features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import '../../features/language_models/domain/repositories/language_model_repository.dart';
import '../../features/language_models/domain/usecases/watch_language_models.dart';
import '../../features/language_models/infrastructure/repositories/local_language_model_repository.dart';
import '../../features/task_builder/domain/repositories/task_repository.dart';
import '../../features/task_builder/domain/usecases/execute_task.dart';
import '../../features/task_builder/infrastructure/datasources/local_http_task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/repositories/local_task_repository.dart';
import '../../features/task_builder/presentation/cubits/task_builder_cubit.dart';
import '../../features/task_builder/presentation/cubits/task_homepage_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_language_models_cubit.dart';
import '../../features/teams/domain/usecases/get_current_team_id.dart';
import '../../features/licensing/domain/repositories/local_runtime_license_repository.dart';
import '../../features/licensing/domain/usecases/activate_local_runtime_license.dart';
import '../../features/licensing/domain/usecases/load_local_runtime_license_status.dart';
import '../../features/licensing/infrastructure/repositories/http_local_runtime_license_repository.dart';
import '../../features/licensing/presentation/cubits/local_runtime_license_cubit.dart';
import '../../features/notifications/domain/repositories/app_notification_repository.dart';
import '../../features/notifications/domain/usecases/accept_team_invitation.dart';
import '../../features/notifications/domain/usecases/reject_team_invitation.dart';
import '../../features/notifications/domain/usecases/watch_app_notifications.dart';
import '../../features/notifications/infrastructure/repositories/local_app_notification_repository.dart';
import '../../features/notifications/presentation/cubits/app_notifications_cubit.dart';
import '../config/runtime_profile.dart';
import '../network/local_runtime_api_client.dart';
import '../routing/app_router.dart';
import 'local_workspace_dependency_configuration.dart';

void configureLocalDependencies(GetIt locator, RuntimeProfile profile) {
  locator.registerLazySingleton<LocalRuntimeApiClient>(
    () => HttpLocalRuntimeApiClient(baseUri: profile.localRuntimeUri),
  );
  locator
    ..registerLazySingleton<AuthRepository>(
      () => const LocalWorkspaceAuthRepository('local-user'),
    )
    ..registerLazySingleton<AppNotificationRepository>(
      LocalAppNotificationRepository.new,
    )
    ..registerLazySingleton(
      () => WatchAppNotifications(locator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => AcceptTeamInvitation(locator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => RejectTeamInvitation(locator<AppNotificationRepository>()),
    );
  configureLocalWorkspaceDependencies(locator);
  locator
    ..registerLazySingleton<LocalRuntimeLicenseRepository>(
      () => HttpLocalRuntimeLicenseRepository(locator<LocalRuntimeApiClient>()),
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
    ..registerLazySingleton<ApplicationLogRepository>(
      () => LocalApplicationLogRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<LanguageModelRepository>(
      () => const LocalLanguageModelRepository(),
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
    ..registerLazySingleton(
      () => WatchApplicationLogs(locator<ApplicationLogRepository>()),
    )
    ..registerLazySingleton(() => ReviewTaskRun(locator<TaskRunRepository>()))
    ..registerLazySingleton(
      () => WatchLanguageModels(locator<LanguageModelRepository>()),
    )
    ..registerLazySingleton(
      () => LoadLocalRuntimeLicenseStatus(
        locator<LocalRuntimeLicenseRepository>(),
      ),
    )
    ..registerLazySingleton(
      () =>
          ActivateLocalRuntimeLicense(locator<LocalRuntimeLicenseRepository>()),
    )
    ..registerLazySingleton(
      () => LocalRuntimeLicenseCubit(
        loadStatus: locator<LoadLocalRuntimeLicenseStatus>(),
        activateLicense: locator<ActivateLocalRuntimeLicense>(),
      )..load(),
      dispose: (cubit) => cubit.close(),
    )
    ..registerFactory(
      () => AppNotificationsCubit(
        locator<WatchAppNotifications>(),
        locator<AcceptTeamInvitation>(),
        locator<RejectTeamInvitation>(),
      )..load(),
    )
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
      () => NodeFileAttachmentsCubit(
        locator<AuthRepository>(),
        locator<WatchTeamFiles>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => NodeKnowledgeAttachmentsCubit(
        locator<AuthRepository>(),
        locator<WatchKnowledgeNotes>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => NodeLanguageModelsCubit(
        locator<AuthRepository>(),
        locator<WatchLanguageModels>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => ActivityCubit(
        watchTaskActivities: locator<WatchTaskActivities>(),
        watchTaskRuns: locator<WatchTaskRuns>(),
        reviewTaskRun: locator<ReviewTaskRun>(),
        mediaInputPicker: locator<MediaInputPicker>(),
        uploadTaskRunMediaInput: locator<UploadTaskRunMediaInput>(),
      ),
    )
    ..registerFactory(
      () => ApplicationLogsCubit(locator<WatchApplicationLogs>()),
    )
    ..registerLazySingleton<AppRouter>(
      AppRouter.local,
      dispose: (router) => router.dispose(),
    );
}
