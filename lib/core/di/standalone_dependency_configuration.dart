import 'package:get_it/get_it.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import '../../features/activity/infrastructure/repositories/team_file_task_run_media_input_repository.dart';
import '../../features/activity/presentation/cubits/activity_cubit.dart';
import '../../features/application_logs/domain/repositories/application_log_repository.dart';
import '../../features/application_logs/domain/usecases/watch_application_logs.dart';
import '../../features/application_logs/infrastructure/repositories/local_application_log_repository.dart';
import '../../features/application_logs/presentation/cubits/application_logs_cubit.dart';
import '../../features/assistant/domain/entities/assistant_context.dart';
import '../../features/assistant/domain/repositories/assistant_repository.dart';
import '../../features/assistant/domain/usecases/ask_assistant.dart';
import '../../features/assistant/infrastructure/datasources/http_runtime_assistant_datasource.dart';
import '../../features/assistant/infrastructure/repositories/routed_assistant_repository.dart';
import '../../features/assistant/presentation/cubits/assistant_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/infrastructure/repositories/local_workspace_auth_repository.dart';
import '../../features/files/domain/usecases/upload_team_file.dart';
import '../../features/data/domain/repositories/data_repository.dart';
import '../../features/data/domain/usecases/data_records.dart';
import '../../features/data/infrastructure/repositories/local_data_repository.dart';
import '../../features/data/presentation/cubits/database_cubit.dart';
import '../../features/files/domain/usecases/watch_team_files.dart';
import '../../features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import '../../features/language_models/domain/repositories/language_model_repository.dart';
import '../../features/language_models/domain/repositories/language_model_connection_repository.dart';
import '../../features/language_models/domain/repositories/language_model_defaults_repository.dart';
import '../../features/language_models/domain/usecases/connect_language_models.dart';
import '../../features/language_models/domain/usecases/remove_language_model_connection.dart';
import '../../features/language_models/domain/usecases/watch_language_model_connections.dart';
import '../../features/language_models/domain/usecases/watch_language_models.dart';
import '../../features/language_models/domain/usecases/save_language_model.dart';
import '../../features/language_models/domain/usecases/watch_language_model_defaults.dart';
import '../../features/language_models/domain/usecases/save_language_model_defaults.dart';
import '../../features/language_models/infrastructure/repositories/local_language_model_repository.dart';
import '../../features/language_models/infrastructure/repositories/local_language_model_defaults_repository.dart';
import '../../features/language_models/presentation/cubits/language_model_connections_cubit.dart';
import '../../features/language_models/presentation/cubits/language_model_defaults_cubit.dart';
import '../../features/language_models/presentation/cubits/language_models_settings_cubit.dart';
import '../../features/machine_learning/domain/repositories/model_catalog_repository.dart';
import '../../features/machine_learning/domain/usecases/import_model_catalog_entry.dart';
import '../../features/machine_learning/domain/usecases/remove_model_catalog_entry.dart';
import '../../features/machine_learning/domain/usecases/watch_model_catalog_entries.dart';
import '../../features/machine_learning/domain/usecases/load_global_model_catalog.dart';
import '../../features/machine_learning/domain/usecases/install_global_model.dart';
import '../../features/machine_learning/infrastructure/repositories/local_model_catalog_repository.dart';
import '../../features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
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
import '../../features/licensing/domain/repositories/runtime_license_repository.dart';
import '../../features/licensing/domain/usecases/activate_runtime_license.dart';
import '../../features/licensing/domain/usecases/load_runtime_license_status.dart';
import '../../features/licensing/domain/usecases/release_runtime_license.dart';
import '../../features/licensing/infrastructure/repositories/http_runtime_license_repository.dart';
import '../../features/licensing/presentation/cubits/runtime_license_cubit.dart';
import '../../features/notifications/domain/repositories/app_notification_repository.dart';
import '../../features/notifications/domain/repositories/push_device_repository.dart';
import '../../features/notifications/domain/usecases/accept_team_invitation.dart';
import '../../features/notifications/domain/usecases/register_push_device.dart';
import '../../features/notifications/domain/usecases/reject_team_invitation.dart';
import '../../features/notifications/domain/usecases/unregister_push_device.dart';
import '../../features/notifications/domain/usecases/watch_app_notifications.dart';
import '../../features/notifications/infrastructure/datasources/firebase_messaging_token_provider.dart';
import '../../features/notifications/infrastructure/repositories/local_app_notification_repository.dart';
import '../../features/notifications/infrastructure/repositories/local_relay_push_device_repository.dart';
import '../../features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import '../../features/notifications/presentation/cubits/app_notifications_cubit.dart';
import '../runtime/runtime_credential_store.dart';
import '../runtime/runtime_endpoint.dart';
import '../runtime/runtime_profile.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_binary_client.dart';
import '../network/workspace_realtime_channel.dart';
import '../routing/app_router.dart';
import 'standalone_workspace_dependency_configuration.dart';
import 'standalone_workspace_transfer_dependency_configuration.dart';

Future<void> configureStandaloneDependencies(
  GetIt locator,
  RuntimeProfile profile,
) async {
  final credentials = SecureRuntimeCredentialStore();
  final endpoint = RuntimeEndpoint.fromUri(profile.workspaceApiUri);
  locator.registerLazySingleton<WorkspaceApiClient>(
    () => HttpWorkspaceApiClient(
      baseUri: profile.workspaceApiUri,
      authHeaderProvider: () async {
        final token = await credentials.sessionToken(endpoint.address);
        return token == null ? null : 'Bearer $token';
      },
    ),
  );
  locator.registerLazySingleton<WorkspaceBinaryClient>(
    () => HttpWorkspaceBinaryClient(
      baseUri: profile.workspaceApiUri,
      authHeaderProvider: () async {
        final token = await credentials.sessionToken(endpoint.address);
        return token == null ? null : 'Bearer $token';
      },
    ),
  );
  locator.registerLazySingleton<WorkspaceRealtimeChannel>(
    () => WorkspaceRealtimeChannel(
      profile.workspaceApiUri,
      locator<WorkspaceApiClient>(),
    ),
    dispose: (channel) => channel.close(),
  );
  locator
    ..registerLazySingleton<AuthRepository>(
      () => const LocalWorkspaceAuthRepository('local-user'),
    )
    ..registerLazySingleton<AppNotificationRepository>(
      LocalAppNotificationRepository.new,
    )
    ..registerLazySingleton<PushDeviceRepository>(
      () => LocalRelayPushDeviceRepository(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton(
      () => FirebaseMessagingTokenProvider(FirebaseMessaging.instance),
    )
    ..registerLazySingleton(
      () => WatchAppNotifications(locator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => AcceptTeamInvitation(locator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => RejectTeamInvitation(locator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => RegisterPushDevice(locator<PushDeviceRepository>()),
    )
    ..registerLazySingleton(
      () => UnregisterPushDevice(locator<PushDeviceRepository>()),
    )
    ..registerLazySingleton(
      () => FcmBootstrapper(
        locator<AuthRepository>(),
        locator<FirebaseMessagingTokenProvider>(),
        locator<RegisterPushDevice>(),
        locator<UnregisterPushDevice>(),
      ),
      dispose: (bootstrapper) => bootstrapper.dispose(),
    );
  configureStandaloneWorkspaceDependencies(locator);
  configureStandaloneWorkspaceTransferDependencies(locator);
  locator
    ..registerLazySingleton<RuntimeLicenseRepository>(
      () => HttpRuntimeLicenseRepository(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton<AssistantRepository>(
      () => RoutedAssistantRepository(
        HttpRuntimeTaskBuilderAssistantDatasource(locator<WorkspaceApiClient>()),
        HttpRuntimeKnowledgeBaseAssistantDatasource(locator<WorkspaceApiClient>()),
      ),
    )
    ..registerLazySingleton<TaskRunnerDatasource>(
      () => LocalHttpTaskRunnerDatasource(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton<TaskRepository>(
      () => LocalTaskRepository(
        locator<WorkspaceApiClient>(),
        locator<TaskRunnerDatasource>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<TaskRunRepository>(
      () => LocalTaskRunRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<TaskActivityRepository>(
      () => LocalTaskActivityRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<DataRepository>(
      () => LocalDataRepository(locator<WorkspaceApiClient>()),
    )
    ..registerLazySingleton<ApplicationLogRepository>(
      () => LocalApplicationLogRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<LanguageModelRepository>(
      () => LocalLanguageModelRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<LanguageModelDefaultsRepository>(
      () => LocalLanguageModelDefaultsRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<ModelCatalogRepository>(
      () => LocalModelCatalogRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton<GlobalModelCatalogRepository>(
      () => locator<ModelCatalogRepository>() as GlobalModelCatalogRepository,
    )
    ..registerLazySingleton<LanguageModelConnectionRepository>(
      () =>
          locator<LanguageModelRepository>()
              as LanguageModelConnectionRepository,
    )
    ..registerLazySingleton<TaskRunMediaInputRepository>(
      () => TeamFileTaskRunMediaInputRepository(
        locator<AuthRepository>(),
        locator<GetCurrentTeamId>(),
        locator<UploadTeamFile>(),
      ),
    )
    ..registerLazySingleton<MediaInputPicker>(
      () => ImagePickerMediaInputPicker(ImagePicker()),
    )
    ..registerLazySingleton(
      () => ListDataCollections(locator<DataRepository>()),
    )
    ..registerLazySingleton(() => QueryDataRecords(locator<DataRepository>()))
    ..registerLazySingleton(() => CreateDataRecord(locator<DataRepository>()))
    ..registerLazySingleton(() => UpdateDataRecord(locator<DataRepository>()))
    ..registerLazySingleton(() => DeleteDataRecord(locator<DataRepository>()))
    ..registerLazySingleton(() => ExecuteTask(locator<TaskRepository>()))
    ..registerLazySingleton(
      () => AskAssistant(locator<AssistantRepository>()),
    )
    ..registerFactory(
      () => AssistantCubit(
        askAssistant: locator<AskAssistant>(),
        context: const AssistantContext(
          area: AssistantArea.general,
          route: '/',
        ),
      ),
    )
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
      () => SaveLanguageModel(locator<LanguageModelRepository>()),
    )
    ..registerLazySingleton(
      () => WatchLanguageModelDefaults(
        locator<LanguageModelDefaultsRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => SaveLanguageModelDefaults(
        locator<LanguageModelDefaultsRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => ConnectLanguageModels(locator<LanguageModelConnectionRepository>()),
    )
    ..registerLazySingleton(
      () => WatchLanguageModelConnections(
        locator<LanguageModelConnectionRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => RemoveLanguageModelConnection(
        locator<LanguageModelConnectionRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchModelCatalogEntries(locator<ModelCatalogRepository>()),
    )
    ..registerLazySingleton(
      () => ImportModelCatalogEntry(locator<ModelCatalogRepository>()),
    )
    ..registerLazySingleton(
      () => RemoveModelCatalogEntry(locator<ModelCatalogRepository>()),
    )
    ..registerLazySingleton(
      () => LoadGlobalModelCatalog(locator<GlobalModelCatalogRepository>()),
    )
    ..registerLazySingleton(
      () => InstallGlobalModel(locator<GlobalModelCatalogRepository>()),
    )
    ..registerLazySingleton(
      () => LoadRuntimeLicenseStatus(locator<RuntimeLicenseRepository>()),
    )
    ..registerLazySingleton(
      () => ActivateRuntimeLicense(locator<RuntimeLicenseRepository>()),
    )
    ..registerLazySingleton(
      () => ReleaseRuntimeLicense(locator<RuntimeLicenseRepository>()),
    )
    ..registerLazySingleton(
      () => RuntimeLicenseCubit(
        loadStatus: locator<LoadRuntimeLicenseStatus>(),
        activateLicense: locator<ActivateRuntimeLicense>(),
        releaseLicense: locator<ReleaseRuntimeLicense>(),
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
      () => DatabaseCubit(
        listCollections: locator<ListDataCollections>(),
        queryRecords: locator<QueryDataRecords>(),
        createRecord: locator<CreateDataRecord>(),
        updateRecord: locator<UpdateDataRecord>(),
        deleteRecord: locator<DeleteDataRecord>(),
      ),
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
      () => LanguageModelsSettingsCubit(
        locator<AuthRepository>(),
        locator<WatchLanguageModels>(),
        locator<SaveLanguageModel>(),
        locator<GetCurrentTeamId>(),
        allowsKeylessLocalEndpoint: true,
        connectLanguageModels: locator<ConnectLanguageModels>(),
      ),
    )
    ..registerFactory(
      () => LanguageModelConnectionsCubit(
        locator<AuthRepository>(),
        locator<WatchLanguageModelConnections>(),
        locator<RemoveLanguageModelConnection>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => LanguageModelDefaultsCubit(
        locator<AuthRepository>(),
        locator<WatchLanguageModels>(),
        locator<WatchLanguageModelDefaults>(),
        locator<SaveLanguageModelDefaults>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => ModelCatalogCubit(
        locator<WatchModelCatalogEntries>(),
        locator<ImportModelCatalogEntry>(),
        locator<RemoveModelCatalogEntry>(),
        locator<LoadGlobalModelCatalog>(),
        locator<InstallGlobalModel>(),
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
      AppRouter.standalone,
      dispose: (router) => router.dispose(),
    );
}
