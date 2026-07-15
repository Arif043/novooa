import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/create_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/delete_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/dispatch_fake_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/watch_communication_channels.dart';
import 'package:syscat2/features/communication/infrastructure/repositories/firestore_communication_channel_repository.dart';
import 'package:syscat2/features/communication/presentation/cubits/communication_cubit.dart';
import 'package:syscat2/features/files/domain/repositories/team_file_repository.dart';
import 'package:syscat2/features/files/domain/usecases/create_team_folder.dart';
import 'package:syscat2/features/files/domain/usecases/upload_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_files.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_folders.dart';
import 'package:syscat2/features/files/infrastructure/repositories/firebase_team_file_repository.dart';
import 'package:syscat2/features/files/presentation/cubits/files_cubit.dart';
import 'package:syscat2/features/knowledge_base/domain/repositories/knowledge_base_repository.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/create_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/delete_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/update_knowledge_note.dart';
import 'package:syscat2/features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import 'package:syscat2/features/knowledge_base/infrastructure/repositories/firestore_knowledge_base_repository.dart';
import 'package:syscat2/features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';
import 'package:syscat2/features/notifications/domain/repositories/app_notification_repository.dart';
import 'package:syscat2/features/notifications/domain/usecases/accept_team_invitation.dart';
import 'package:syscat2/features/notifications/domain/repositories/notification_device_repository.dart';
import 'package:syscat2/features/notifications/domain/usecases/reject_team_invitation.dart';
import 'package:syscat2/features/notifications/domain/usecases/register_notification_device.dart';
import 'package:syscat2/features/notifications/domain/usecases/unregister_notification_device.dart';
import 'package:syscat2/features/notifications/domain/usecases/watch_app_notifications.dart';
import 'package:syscat2/features/notifications/infrastructure/datasources/firebase_messaging_token_provider.dart';
import 'package:syscat2/features/notifications/infrastructure/repositories/firestore_app_notification_repository.dart';
import 'package:syscat2/features/notifications/infrastructure/repositories/firestore_notification_device_repository.dart';
import 'package:syscat2/features/notifications/infrastructure/services/fcm_bootstrapper.dart';
import 'package:syscat2/features/notifications/presentation/cubits/app_notifications_cubit.dart';
import 'package:syscat2/features/schedule/domain/repositories/task_trigger_repository.dart';
import 'package:syscat2/features/schedule/domain/usecases/create_task_trigger.dart';
import 'package:syscat2/features/schedule/domain/usecases/delete_task_trigger.dart';
import 'package:syscat2/features/schedule/domain/usecases/set_task_trigger_enabled.dart';
import 'package:syscat2/features/schedule/domain/usecases/watch_task_triggers.dart';
import 'package:syscat2/features/schedule/infrastructure/repositories/firestore_task_trigger_repository.dart';
import 'package:syscat2/features/schedule/presentation/cubits/schedule_cubit.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import '../../features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import '../../features/auth/presentation/cubits/auth_cubit.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/get_ai_model_settings.dart';
import '../../features/settings/domain/usecases/save_ai_provider_settings.dart';
import '../../features/settings/infrastructure/repositories/firestore_settings_repository.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';
import '../../features/activity/domain/repositories/task_activity_repository.dart';
import '../../features/activity/domain/repositories/task_run_repository.dart';
import '../../features/activity/domain/usecases/list_task_activities.dart';
import '../../features/activity/domain/usecases/list_task_runs.dart';
import '../../features/activity/domain/usecases/review_task_run.dart';
import '../../features/activity/infrastructure/repositories/firestore_task_activity_repository.dart';
import '../../features/activity/infrastructure/repositories/firestore_task_run_repository.dart';
import '../../features/activity/presentation/cubits/activity_cubit.dart';
import '../../features/task_builder/domain/repositories/task_repository.dart';
import '../../features/task_builder/domain/usecases/execute_task.dart';
import '../../features/task_builder/infrastructure/datasources/firebase_functions_task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/repositories/firebase_task_repository.dart';
import '../../features/task_builder/presentation/cubits/task_builder_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/task_homepage_cubit.dart';
import '../../features/teams/domain/repositories/team_repository.dart';
import '../../features/teams/domain/usecases/add_current_team_member.dart';
import '../../features/teams/domain/usecases/get_current_team_id.dart';
import '../../features/teams/domain/usecases/remove_current_team_member.dart';
import '../../features/teams/domain/usecases/update_current_team_name.dart';
import '../../features/teams/domain/usecases/watch_current_team.dart';
import '../../features/teams/domain/usecases/watch_current_team_members.dart';
import '../../features/teams/infrastructure/datasources/firebase_functions_team_member_actions_datasource.dart';
import '../../features/teams/infrastructure/datasources/team_member_actions_datasource.dart';
import '../../features/teams/infrastructure/repositories/firestore_team_repository.dart';
import '../../features/teams/presentation/cubits/team_settings_cubit.dart';
import '../../features/user/domain/repositories/user_repository.dart';
import '../../features/user/domain/usecases/ensure_user_profile.dart';
import '../../features/user/domain/usecases/get_user_profile.dart';
import '../../features/user/infrastructure/repositories/firestore_user_repository.dart';
import '../routing/app_router.dart';

final serviceLocator = GetIt.instance;

void configureDependencies() {
  serviceLocator
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance)
    ..registerLazySingleton<FirebaseMessaging>(() => FirebaseMessaging.instance)
    ..registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance)
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(serviceLocator<FirebaseAuth>()),
    )
    ..registerLazySingleton<UserRepository>(
      () => FirestoreUserRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => FirestoreSettingsRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<TeamFileRepository>(
      () => FirebaseTeamFileRepository(
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<FirebaseStorage>(),
      ),
    )
    ..registerLazySingleton<KnowledgeBaseRepository>(
      () =>
          FirestoreKnowledgeBaseRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<TaskRepository>(
      () => FirebaseTaskRepository(
        auth: serviceLocator<FirebaseAuth>(),
        firestore: serviceLocator<FirebaseFirestore>(),
        runnerDatasource: serviceLocator<TaskRunnerDatasource>(),
        teamRepository: serviceLocator<TeamRepository>(),
      ),
    )
    ..registerLazySingleton<TaskActivityRepository>(
      () => FirestoreTaskActivityRepository(
        serviceLocator<FirebaseAuth>(),
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<TeamRepository>(),
      ),
    )
    ..registerLazySingleton<TaskRunRepository>(
      () => FirestoreTaskRunRepository(
        serviceLocator<FirebaseAuth>(),
        serviceLocator<FirebaseFirestore>(),
        teamRepository: serviceLocator<TeamRepository>(),
      ),
    )
    ..registerLazySingleton<TaskTriggerRepository>(
      () => FirestoreTaskTriggerRepository(
        serviceLocator<AuthRepository>(),
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<TeamRepository>(),
      ),
    )
    ..registerLazySingleton<CommunicationChannelRepository>(
      () => FirestoreCommunicationChannelRepository(
        serviceLocator<AuthRepository>(),
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<TeamRepository>(),
      ),
    )
    ..registerLazySingleton<NotificationDeviceRepository>(
      () => FirestoreNotificationDeviceRepository(
        serviceLocator<FirebaseFirestore>(),
      ),
    )
    ..registerLazySingleton<AppNotificationRepository>(
      () => FirestoreAppNotificationRepository(
        serviceLocator<FirebaseAuth>(),
        serviceLocator<FirebaseFirestore>(),
      ),
    )
    ..registerLazySingleton<TeamRepository>(
      () => FirestoreTeamRepository(
        serviceLocator<AuthRepository>(),
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<TeamMemberActionsDatasource>(),
      ),
    )
    ..registerLazySingleton<TeamMemberActionsDatasource>(
      FirebaseFunctionsTeamMemberActionsDatasource.new,
    )
    ..registerLazySingleton(
      () => FirebaseMessagingTokenProvider(serviceLocator<FirebaseMessaging>()),
    )
    ..registerLazySingleton<TaskRunnerDatasource>(
      FirebaseFunctionsTaskRunnerDatasource.new,
    )
    ..registerLazySingleton(() => SignOut(serviceLocator<AuthRepository>()))
    ..registerLazySingleton(
      () => SignUpWithEmailAndPassword(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => SignInWithEmailAndPassword(serviceLocator<AuthRepository>()),
    )
    ..registerLazySingleton(
      () => EnsureUserProfile(serviceLocator<UserRepository>()),
    )
    ..registerLazySingleton(
      () => GetUserProfile(serviceLocator<UserRepository>()),
    )
    ..registerLazySingleton(
      () => GetCurrentUserProfile(
        authRepository: serviceLocator<AuthRepository>(),
        userRepository: serviceLocator<UserRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => GetAiModelSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => SaveAiProviderSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => ListTaskActivities(serviceLocator<TaskActivityRepository>()),
    )
    ..registerLazySingleton(
      () => ListTaskRuns(serviceLocator<TaskRunRepository>()),
    )
    ..registerLazySingleton(
      () => ReviewTaskRun(serviceLocator<TaskRunRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTeamFiles(serviceLocator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTeamFolders(serviceLocator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => WatchKnowledgeNotes(serviceLocator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => CreateKnowledgeNote(serviceLocator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateKnowledgeNote(serviceLocator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteKnowledgeNote(serviceLocator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => UploadTeamFile(serviceLocator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => CreateTeamFolder(serviceLocator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTaskTriggers(serviceLocator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => CreateTaskTrigger(serviceLocator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => SetTaskTriggerEnabled(serviceLocator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteTaskTrigger(serviceLocator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchCommunicationChannels(
        serviceLocator<CommunicationChannelRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => CreateCommunicationChannel(
        serviceLocator<CommunicationChannelRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => DeleteCommunicationChannel(
        serviceLocator<CommunicationChannelRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => DispatchFakeChannelMessage(
        serviceLocator<CommunicationChannelRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => RegisterNotificationDevice(
        serviceLocator<NotificationDeviceRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchAppNotifications(serviceLocator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => AcceptTeamInvitation(serviceLocator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => RejectTeamInvitation(serviceLocator<AppNotificationRepository>()),
    )
    ..registerLazySingleton(
      () => UnregisterNotificationDevice(
        serviceLocator<NotificationDeviceRepository>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchCurrentTeam(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => GetCurrentTeamId(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => WatchCurrentTeamMembers(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateCurrentTeamName(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => AddCurrentTeamMember(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => RemoveCurrentTeamMember(serviceLocator<TeamRepository>()),
    )
    ..registerLazySingleton(
      () => FcmBootstrapper(
        serviceLocator<AuthRepository>(),
        serviceLocator<FirebaseMessagingTokenProvider>(),
        serviceLocator<RegisterNotificationDevice>(),
        serviceLocator<UnregisterNotificationDevice>(),
      ),
      dispose: (bootstrapper) => bootstrapper.dispose(),
    )
    ..registerLazySingleton(() => ExecuteTask(serviceLocator<TaskRepository>()))
    ..registerFactory(
      () => AuthCubit(
        signUp: serviceLocator<SignUpWithEmailAndPassword>(),
        signIn: serviceLocator<SignInWithEmailAndPassword>(),
        signOut: serviceLocator<SignOut>(),
        ensureUserProfile: serviceLocator<EnsureUserProfile>(),
      ),
    )
    ..registerFactory(
      () => SettingsCubit(
        getCurrentUserProfile: serviceLocator<GetCurrentUserProfile>(),
        ensureUserProfile: serviceLocator<EnsureUserProfile>(),
        getAiModelSettings: serviceLocator<GetAiModelSettings>(),
        saveAiProviderSettings: serviceLocator<SaveAiProviderSettings>(),
      ),
    )
    ..registerFactory(
      () => TaskBuilderCubit(repository: serviceLocator<TaskRepository>()),
    )
    ..registerFactory(() => TaskHomepageCubit(serviceLocator<TaskRepository>()))
    ..registerFactory(
      () => NodeFileAttachmentsCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchTeamFiles>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => NodeKnowledgeAttachmentsCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchKnowledgeNotes>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => KnowledgeBaseCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchKnowledgeNotes>(),
        serviceLocator<CreateKnowledgeNote>(),
        serviceLocator<UpdateKnowledgeNote>(),
        serviceLocator<DeleteKnowledgeNote>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => ActivityCubit(
        listTaskActivities: serviceLocator<ListTaskActivities>(),
        listTaskRuns: serviceLocator<ListTaskRuns>(),
        reviewTaskRun: serviceLocator<ReviewTaskRun>(),
      ),
    )
    ..registerFactory(
      () => FilesCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchTeamFiles>(),
        serviceLocator<WatchTeamFolders>(),
        serviceLocator<UploadTeamFile>(),
        serviceLocator<CreateTeamFolder>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => ScheduleCubit(
        watchTaskTriggers: serviceLocator<WatchTaskTriggers>(),
        createTaskTrigger: serviceLocator<CreateTaskTrigger>(),
        setTaskTriggerEnabled: serviceLocator<SetTaskTriggerEnabled>(),
        deleteTaskTrigger: serviceLocator<DeleteTaskTrigger>(),
        taskRepository: serviceLocator<TaskRepository>(),
      ),
    )
    ..registerFactory(
      () => CommunicationCubit(
        serviceLocator<WatchCommunicationChannels>(),
        serviceLocator<CreateCommunicationChannel>(),
        serviceLocator<DeleteCommunicationChannel>(),
        serviceLocator<DispatchFakeChannelMessage>(),
      ),
    )
    ..registerFactory(
      () => TeamSettingsCubit(
        serviceLocator<WatchCurrentTeam>(),
        serviceLocator<WatchCurrentTeamMembers>(),
        serviceLocator<UpdateCurrentTeamName>(),
        serviceLocator<AddCurrentTeamMember>(),
        serviceLocator<RemoveCurrentTeamMember>(),
      ),
    )
    ..registerFactory(
      () => AppNotificationsCubit(
        serviceLocator<WatchAppNotifications>(),
        serviceLocator<AcceptTeamInvitation>(),
        serviceLocator<RejectTeamInvitation>(),
      )..load(),
    )
    ..registerLazySingleton(
      () => AppRouter(authRepository: serviceLocator<AuthRepository>()),
      dispose: (router) => router.dispose(),
    );
}
