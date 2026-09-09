import 'package:get_it/get_it.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/files/domain/repositories/file_version_repository.dart';
import '../../features/files/domain/repositories/team_file_repository.dart';
import '../../features/files/domain/usecases/create_file_version.dart';
import '../../features/files/domain/usecases/create_team_folder.dart';
import '../../features/files/domain/usecases/download_file_version.dart';
import '../../features/files/domain/usecases/upload_team_file.dart';
import '../../features/files/domain/usecases/watch_file_versions.dart';
import '../../features/files/domain/usecases/watch_team_files.dart';
import '../../features/files/domain/usecases/watch_team_folders.dart';
import '../../features/files/infrastructure/repositories/local_team_file_repository.dart';
import '../../features/files/presentation/cubits/file_detail_cubit.dart';
import '../../features/files/presentation/cubits/files_cubit.dart';
import '../../features/knowledge_base/domain/repositories/knowledge_base_repository.dart';
import '../../features/knowledge_base/domain/usecases/create_knowledge_note.dart';
import '../../features/knowledge_base/domain/usecases/delete_knowledge_note.dart';
import '../../features/knowledge_base/domain/usecases/restore_knowledge_note.dart';
import '../../features/knowledge_base/domain/usecases/update_knowledge_note.dart';
import '../../features/knowledge_base/domain/usecases/watch_knowledge_notes.dart';
import '../../features/knowledge_base/infrastructure/repositories/local_knowledge_base_repository.dart';
import '../../features/knowledge_base/presentation/cubits/knowledge_base_cubit.dart';
import '../../features/schedule/domain/repositories/task_trigger_repository.dart';
import '../../features/schedule/domain/usecases/create_task_trigger.dart';
import '../../features/schedule/domain/usecases/delete_task_trigger.dart';
import '../../features/schedule/domain/usecases/set_task_trigger_enabled.dart';
import '../../features/schedule/domain/usecases/watch_task_triggers.dart';
import '../../features/schedule/infrastructure/repositories/local_task_trigger_repository.dart';
import '../../features/schedule/presentation/cubits/schedule_cubit.dart';
import '../../features/task_builder/domain/repositories/task_repository.dart';
import '../../features/teams/domain/repositories/team_repository.dart';
import '../../features/teams/domain/usecases/get_current_team_id.dart';
import '../../features/teams/infrastructure/repositories/local_workspace_team_repository.dart';
import '../network/local_runtime_api_client.dart';

void configureLocalWorkspaceDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<TeamRepository>(
      () => const LocalWorkspaceTeamRepository(
        teamId: 'local-team',
        userId: 'local-user',
      ),
    )
    ..registerLazySingleton<TeamFileRepository>(
      () => LocalTeamFileRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<FileVersionRepository>(
      () => locator<TeamFileRepository>() as FileVersionRepository,
    )
    ..registerLazySingleton<KnowledgeBaseRepository>(
      () => LocalKnowledgeBaseRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton<TaskTriggerRepository>(
      () => LocalTaskTriggerRepository(locator<LocalRuntimeApiClient>()),
    )
    ..registerLazySingleton(() => GetCurrentTeamId(locator<TeamRepository>()))
    ..registerLazySingleton(() => WatchTeamFiles(locator<TeamFileRepository>()))
    ..registerLazySingleton(
      () => WatchTeamFolders(locator<TeamFileRepository>()),
    )
    ..registerLazySingleton(() => UploadTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(
      () => CreateTeamFolder(locator<TeamFileRepository>()),
    )
    ..registerLazySingleton(
      () => WatchFileVersions(locator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => DownloadFileVersion(locator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => CreateFileVersion(locator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => WatchKnowledgeNotes(locator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => CreateKnowledgeNote(locator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => UpdateKnowledgeNote(locator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteKnowledgeNote(locator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => RestoreKnowledgeNote(locator<KnowledgeBaseRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTaskTriggers(locator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => CreateTaskTrigger(locator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => SetTaskTriggerEnabled(locator<TaskTriggerRepository>()),
    )
    ..registerLazySingleton(
      () => DeleteTaskTrigger(locator<TaskTriggerRepository>()),
    )
    ..registerFactory(
      () => FilesCubit(
        locator<AuthRepository>(),
        locator<WatchTeamFiles>(),
        locator<WatchTeamFolders>(),
        locator<UploadTeamFile>(),
        locator<CreateTeamFolder>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => FileDetailCubit(
        locator<AuthRepository>(),
        locator<WatchFileVersions>(),
        locator<DownloadFileVersion>(),
        locator<CreateFileVersion>(),
      ),
    )
    ..registerFactory(
      () => KnowledgeBaseCubit(
        locator<AuthRepository>(),
        locator<WatchKnowledgeNotes>(),
        locator<CreateKnowledgeNote>(),
        locator<UpdateKnowledgeNote>(),
        locator<DeleteKnowledgeNote>(),
        locator<RestoreKnowledgeNote>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => ScheduleCubit(
        watchTaskTriggers: locator<WatchTaskTriggers>(),
        createTaskTrigger: locator<CreateTaskTrigger>(),
        setTaskTriggerEnabled: locator<SetTaskTriggerEnabled>(),
        deleteTaskTrigger: locator<DeleteTaskTrigger>(),
        taskRepository: locator<TaskRepository>(),
      ),
    );
}
