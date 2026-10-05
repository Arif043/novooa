import 'package:get_it/get_it.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_archive_gateway.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_install_repository.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:syscat2/features/plugins/domain/usecases/plugin_use_cases.dart';
import 'package:syscat2/features/plugins/infrastructure/datasources/file_picker_plugin_archive_gateway.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_install_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugin_registry_cubit.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

/// Use Cases und Cubits der Plugins — in beiden Betriebsvarianten gleich; nur
/// die Repositories unterscheiden sich und werden vorher registriert.
void registerPluginDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<PluginArchiveGateway>(
      FilePickerPluginArchiveGateway.new,
    )
    ..registerLazySingleton(() => WatchPlugins(locator<PluginRepository>()))
    ..registerLazySingleton(() => UninstallPlugin(locator<PluginRepository>()))
    ..registerLazySingleton(
      () => LoadPluginSettings(locator<PluginRepository>()),
    )
    ..registerLazySingleton(
      () => SavePluginSettings(locator<PluginRepository>()),
    )
    ..registerLazySingleton(
      () => LoadPluginCatalog(locator<PluginInstallRepository>()),
    )
    ..registerLazySingleton(
      () => PreviewPluginFromCatalog(locator<PluginInstallRepository>()),
    )
    ..registerLazySingleton(
      () => PreviewPluginFromArchive(locator<PluginInstallRepository>()),
    )
    ..registerLazySingleton(
      () => CommitPluginInstall(locator<PluginInstallRepository>()),
    )
    ..registerFactory(
      () => PluginsCubit(
        locator<WatchPlugins>(),
        locator<UninstallPlugin>(),
        locator<GetCurrentTeamId>(),
      ),
    )
    ..registerFactory(
      () => PluginInstallCubit(
        locator<PreviewPluginFromCatalog>(),
        locator<PreviewPluginFromArchive>(),
        locator<CommitPluginInstall>(),
        locator<PluginArchiveGateway>(),
      ),
    )
    // Ein Register für die ganze App: Palette, Bausteine und Trigger lesen dieselbe Liste.
    ..registerLazySingleton(
      () => PluginRegistryCubit(
        locator<WatchPlugins>(),
        locator<GetCurrentTeamId>(),
      ),
    );
}
