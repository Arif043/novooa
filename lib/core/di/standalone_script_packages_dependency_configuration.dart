import 'package:get_it/get_it.dart';

import '../../features/script_packages/domain/repositories/script_package_repository.dart';
import '../../features/script_packages/domain/usecases/install_script_packages.dart';
import '../../features/script_packages/domain/usecases/watch_script_package_environments.dart';
import '../../features/script_packages/infrastructure/repositories/local_script_package_repository.dart';
import '../../features/script_packages/presentation/cubits/script_packages_cubit.dart';
import '../network/workspace_api_client.dart';
import '../network/workspace_realtime_channel.dart';

/// Python-Pakete für Script-Bausteine gibt es nur in der lokalen Runtime.
void configureStandaloneScriptPackagesDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<ScriptPackageRepository>(
      () => LocalScriptPackageRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton(
      () => WatchScriptPackageEnvironments(locator<ScriptPackageRepository>()),
    )
    ..registerLazySingleton(
      () => InstallScriptPackages(locator<ScriptPackageRepository>()),
    )
    ..registerFactory(
      () => ScriptPackagesCubit(
        locator<WatchScriptPackageEnvironments>(),
        locator<InstallScriptPackages>(),
      ),
    );
}
