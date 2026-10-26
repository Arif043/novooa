import 'package:get_it/get_it.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/plugins/domain/repositories/plugin_repository.dart';
import 'package:syscat2/features/plugins/domain/usecases/set_plugin_enabled.dart';
import 'package:syscat2/features/plugins/domain/usecases/watch_plugins.dart';
import 'package:syscat2/features/plugins/infrastructure/repositories/http_plugin_repository.dart';
import 'package:syscat2/features/plugins/presentation/cubits/plugins_cubit.dart';

/// Plugins der Runtime: ein app-weiter Cubit, den Palette, Leinwand,
/// Auslöser und Einstellungen gemeinsam lesen.
void registerPluginDependencies(GetIt locator) {
  locator
    ..registerLazySingleton<PluginRepository>(
      () => HttpPluginRepository(
        locator<WorkspaceApiClient>(),
        locator<WorkspaceRealtimeChannel>(),
      ),
    )
    ..registerLazySingleton(() => WatchPlugins(locator<PluginRepository>()))
    ..registerLazySingleton(() => SetPluginEnabled(locator<PluginRepository>()))
    ..registerLazySingleton(
      () =>
          PluginsCubit(locator<WatchPlugins>(), locator<SetPluginEnabled>())
            ..start(),
      dispose: (cubit) => cubit.close(),
    );
}
