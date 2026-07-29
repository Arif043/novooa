import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:syscat2/features/assistant/domain/entities/assistant_context.dart';
import 'package:syscat2/features/assistant/domain/repositories/assistant_repository.dart';
import 'package:syscat2/features/assistant/domain/usecases/ask_assistant.dart';
import 'package:syscat2/features/assistant/infrastructure/datasources/firebase_ai_assistant_datasource.dart';
import 'package:syscat2/features/assistant/infrastructure/datasources/internal_assistant_knowledge.dart';
import 'package:syscat2/features/assistant/infrastructure/repositories/firebase_ai_assistant_repository.dart';
import 'package:syscat2/features/assistant/presentation/cubits/assistant_cubit.dart';
import 'package:syscat2/features/communication/domain/repositories/communication_channel_repository.dart';
import 'package:syscat2/features/communication/domain/usecases/create_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/delete_communication_channel.dart';
import 'package:syscat2/features/communication/domain/usecases/dispatch_fake_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/send_channel_message.dart';
import 'package:syscat2/features/communication/domain/usecases/watch_communication_channels.dart';
import 'package:syscat2/features/communication/infrastructure/repositories/firestore_communication_channel_repository.dart';
import 'package:syscat2/features/communication/presentation/cubits/communication_cubit.dart';
import 'package:syscat2/features/files/domain/repositories/team_file_repository.dart';
import 'package:syscat2/features/files/domain/repositories/file_version_repository.dart';
import 'package:syscat2/features/files/domain/usecases/create_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/create_team_folder.dart';
import 'package:syscat2/features/files/domain/usecases/download_file_version.dart';
import 'package:syscat2/features/files/domain/usecases/upload_team_file.dart';
import 'package:syscat2/features/files/domain/usecases/watch_file_versions.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_files.dart';
import 'package:syscat2/features/files/domain/usecases/watch_team_folders.dart';
import 'package:syscat2/features/files/infrastructure/repositories/firebase_team_file_repository.dart';
import 'package:syscat2/features/files/presentation/cubits/files_cubit.dart';
import 'package:syscat2/features/files/presentation/cubits/file_detail_cubit.dart';
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
import 'package:syscat2/features/employees/domain/repositories/employee_repository.dart';
import 'package:syscat2/features/employees/domain/usecases/create_employee.dart';
import 'package:syscat2/features/employees/domain/usecases/delete_employee.dart';
import 'package:syscat2/features/employees/domain/usecases/update_employee.dart';
import 'package:syscat2/features/employees/domain/usecases/watch_employees.dart';
import 'package:syscat2/features/employees/infrastructure/repositories/firestore_employee_repository.dart';
import 'package:syscat2/features/employees/presentation/cubits/employees_cubit.dart';
import 'package:syscat2/features/skills/domain/repositories/skill_repository.dart';
import 'package:syscat2/features/skills/domain/usecases/create_skill.dart';
import 'package:syscat2/features/skills/domain/usecases/delete_skill.dart';
import 'package:syscat2/features/skills/domain/usecases/load_skill_content.dart';
import 'package:syscat2/features/skills/domain/usecases/update_skill.dart';
import 'package:syscat2/features/skills/domain/usecases/watch_skills.dart';
import 'package:syscat2/features/skills/infrastructure/repositories/firebase_skill_repository.dart';
import 'package:syscat2/features/skills/presentation/cubits/skills_cubit.dart';
import 'package:syscat2/features/user/domain/usecases/get_current_user_profile.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in_with_email_and_password.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/sign_up_with_email_and_password.dart';
import '../../features/auth/infrastructure/repositories/firebase_auth_repository.dart';
import '../../features/auth/presentation/cubits/auth_form_cubit.dart';
import '../../features/auth/presentation/cubits/auth_session_cubit.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/save_ai_provider_settings.dart';
import '../../features/settings/domain/usecases/watch_ai_model_settings.dart';
import '../../features/settings/infrastructure/repositories/firestore_settings_repository.dart';
import '../../features/settings/presentation/cubits/settings_cubit.dart';
import '../../features/activity/domain/repositories/task_activity_repository.dart';
import '../../features/activity/domain/repositories/task_run_repository.dart';
import '../../features/activity/domain/usecases/review_task_run.dart';
import '../../features/activity/domain/usecases/watch_task_activities.dart';
import '../../features/activity/domain/usecases/watch_task_runs.dart';
import '../../features/activity/infrastructure/repositories/firestore_task_activity_repository.dart';
import '../../features/activity/infrastructure/repositories/firestore_task_run_repository.dart';
import '../../features/activity/presentation/cubits/activity_cubit.dart';
import '../../features/task_builder/domain/repositories/task_repository.dart';
import '../../features/task_builder/domain/usecases/execute_task.dart';
import '../../features/task_builder/infrastructure/datasources/firebase_functions_task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/datasources/task_runner_datasource.dart';
import '../../features/task_builder/infrastructure/repositories/firebase_task_repository.dart';
import '../../features/task_builder/presentation/cubits/task_builder_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_employee_assignments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_file_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_knowledge_attachments_cubit.dart';
import '../../features/task_builder/presentation/cubits/node_skill_attachments_cubit.dart';
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
    ..registerLazySingleton<FileVersionRepository>(
      () => serviceLocator<TeamFileRepository>() as FileVersionRepository,
    )
    ..registerLazySingleton<KnowledgeBaseRepository>(
      () =>
          FirestoreKnowledgeBaseRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton<SkillRepository>(
      () => FirebaseSkillRepository(
        serviceLocator<FirebaseFirestore>(),
        serviceLocator<FirebaseStorage>(),
      ),
    )
    ..registerLazySingleton<EmployeeRepository>(
      () => FirestoreEmployeeRepository(serviceLocator<FirebaseFirestore>()),
    )
    ..registerLazySingleton(InternalAssistantKnowledge.new)
    ..registerLazySingleton(
      () => FirebaseAiAssistantDatasource(
        knowledge: serviceLocator<InternalAssistantKnowledge>(),
      ),
    )
    ..registerLazySingleton<AssistantRepository>(
      () => FirebaseAiAssistantRepository(
        serviceLocator<FirebaseAiAssistantDatasource>(),
      ),
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
      () => WatchAiModelSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => SaveAiProviderSettings(serviceLocator<SettingsRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTaskActivities(serviceLocator<TaskActivityRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTaskRuns(serviceLocator<TaskRunRepository>()),
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
      () => WatchSkills(serviceLocator<SkillRepository>()),
    )
    ..registerLazySingleton(
      () => LoadSkillContent(serviceLocator<SkillRepository>()),
    )
    ..registerLazySingleton(
      () => CreateSkill(serviceLocator<SkillRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateSkill(serviceLocator<SkillRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteSkill(serviceLocator<SkillRepository>()),
    )
    ..registerLazySingleton(
      () => WatchEmployees(serviceLocator<EmployeeRepository>()),
    )
    ..registerLazySingleton(
      () => CreateEmployee(serviceLocator<EmployeeRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateEmployee(serviceLocator<EmployeeRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteEmployee(serviceLocator<EmployeeRepository>()),
    )
    ..registerLazySingleton(
      () => UploadTeamFile(serviceLocator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => WatchFileVersions(serviceLocator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => DownloadFileVersion(serviceLocator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => CreateFileVersion(serviceLocator<FileVersionRepository>()),
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
      () =>
          SendChannelMessage(serviceLocator<CommunicationChannelRepository>()),
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
    ..registerLazySingleton(
      () => AskAssistant(serviceLocator<AssistantRepository>()),
    )
    ..registerLazySingleton(
      () => AuthSessionCubit(
        authRepository: serviceLocator<AuthRepository>(),
        signOutUseCase: serviceLocator<SignOut>(),
        getUserProfileUseCase: serviceLocator<GetUserProfile>(),
      ),
      dispose: (cubit) => cubit.close(),
    )
    ..registerFactory(
      () => AuthFormCubit(
        signUpUseCase: serviceLocator<SignUpWithEmailAndPassword>(),
        signInUseCase: serviceLocator<SignInWithEmailAndPassword>(),
        ensureUserProfileUseCase: serviceLocator<EnsureUserProfile>(),
        signOutUseCase: serviceLocator<SignOut>(),
      ),
    )
    ..registerFactory(
      () => SettingsCubit(
        getCurrentUserProfile: serviceLocator<GetCurrentUserProfile>(),
        ensureUserProfile: serviceLocator<EnsureUserProfile>(),
        watchAiModelSettings: serviceLocator<WatchAiModelSettings>(),
        saveAiProviderSettings: serviceLocator<SaveAiProviderSettings>(),
      ),
    )
    ..registerFactory(
      () => AssistantCubit(
        askAssistant: serviceLocator<AskAssistant>(),
        context: const AssistantContext(
          area: AssistantArea.general,
          route: '/',
        ),
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
      () => NodeSkillAttachmentsCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchSkills>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => SkillsCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchSkills>(),
        serviceLocator<LoadSkillContent>(),
        serviceLocator<CreateSkill>(),
        serviceLocator<UpdateSkill>(),
        serviceLocator<DeleteSkill>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => NodeEmployeeAssignmentsCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchEmployees>(),
        serviceLocator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => EmployeesCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchEmployees>(),
        serviceLocator<CreateEmployee>(),
        serviceLocator<UpdateEmployee>(),
        serviceLocator<DeleteEmployee>(),
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
        watchTaskActivities: serviceLocator<WatchTaskActivities>(),
        watchTaskRuns: serviceLocator<WatchTaskRuns>(),
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
      () => FileDetailCubit(
        serviceLocator<AuthRepository>(),
        serviceLocator<WatchFileVersions>(),
        serviceLocator<DownloadFileVersion>(),
        serviceLocator<CreateFileVersion>(),
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
        serviceLocator<SendChannelMessage>(),
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
      () => AppRouter(sessionCubit: serviceLocator<AuthSessionCubit>()),
      dispose: (router) => router.dispose(),
    );
}
