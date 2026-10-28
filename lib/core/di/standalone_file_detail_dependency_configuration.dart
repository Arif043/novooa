import 'package:get_it/get_it.dart';

import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/files/domain/repositories/file_save_gateway.dart';
import '../../features/files/domain/repositories/file_version_repository.dart';
import '../../features/files/domain/repositories/team_file_repository.dart';
import '../../features/files/domain/usecases/copy_team_file.dart';
import '../../features/files/domain/usecases/create_file_version.dart';
import '../../features/files/domain/usecases/delete_team_file.dart';
import '../../features/files/domain/usecases/find_team_file.dart';
import '../../features/files/domain/usecases/download_file_version.dart';
import '../../features/files/domain/usecases/move_team_file.dart';
import '../../features/files/domain/usecases/rename_team_file.dart';
import '../../features/files/domain/usecases/restore_file_version.dart';
import '../../features/files/domain/usecases/save_file_version_to_device.dart';
import '../../features/files/domain/usecases/watch_file_version_limit.dart';
import '../../features/files/domain/usecases/watch_file_versions.dart';
import '../../features/files/domain/usecases/watch_team_file.dart';
import '../../features/files/domain/usecases/watch_team_folders.dart';
import '../../features/files/infrastructure/gateways/file_picker_file_save_gateway.dart';
import '../../features/files/presentation/cubits/file_actions_cubit.dart';
import '../../features/files/presentation/cubits/file_actions_dependencies.dart';
import '../../features/files/presentation/cubits/file_detail_cubit.dart';

/// Detailseite einer Datei: beobachten, anzeigen und die Dateiaktionen.
/// Baut auf den Repositories aus `configureStandaloneWorkspaceDependencies` auf.
void configureStandaloneFileDetailDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<FileSaveGateway>(
      () => const FilePickerFileSaveGateway(),
    )
    ..registerLazySingleton(() => WatchTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(() => FindTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(() => RenameTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(() => MoveTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(() => CopyTeamFile(locator<TeamFileRepository>()))
    ..registerLazySingleton(
      () => RestoreFileVersion(locator<FileVersionRepository>()),
    )
    ..registerLazySingleton(
      () => SaveFileVersionToDevice(
        locator<FileVersionRepository>(),
        locator<FileSaveGateway>(),
      ),
    )
    ..registerFactory(
      () => FileDetailCubit(
        locator<WatchTeamFile>(),
        locator<WatchFileVersions>(),
        locator<WatchTeamFolders>(),
        locator<WatchFileVersionLimit>(),
        locator<DownloadFileVersion>(),
      ),
    )
    ..registerFactory(
      () => FileActionsCubit(
        locator<AuthRepository>(),
        FileActionsDependencies(
          rename: locator<RenameTeamFile>(),
          move: locator<MoveTeamFile>(),
          copy: locator<CopyTeamFile>(),
          delete: locator<DeleteTeamFile>(),
          restore: locator<RestoreFileVersion>(),
          saveToDevice: locator<SaveFileVersionToDevice>(),
          createVersion: locator<CreateFileVersion>(),
        ),
      ),
    );
}
