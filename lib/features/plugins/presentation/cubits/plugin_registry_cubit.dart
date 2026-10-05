import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/plugin_manifest.dart';
import '../../domain/usecases/plugin_use_cases.dart';

/// Die Manifeste der installierten Plugins — app-weit, damit Palette,
/// Baustein-Konfiguration und Trigger-Dialog dieselbe Liste sehen. Läuft erst,
/// wenn jemand sie braucht ([ensureLoaded]).
class PluginRegistryCubit extends Cubit<List<PluginManifest>> {
  PluginRegistryCubit(this._watchPlugins, this._getCurrentTeamId)
    : super(const []);

  final WatchPlugins _watchPlugins;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<Object?>? _subscription;
  bool _started = false;

  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    try {
      final teamId = await _getCurrentTeamId();
      _subscription = _watchPlugins(teamId).listen(
        (plugins) {
          if (!isClosed) {
            emit(
              plugins.map((plugin) => plugin.manifest).toList(growable: false),
            );
          }
        },
        onError: (Object error, StackTrace stackTrace) =>
            _logLoadFailure(error, stackTrace),
      );
    } catch (error, stackTrace) {
      // Erneut versuchbar, etwa nachdem das Team bekannt ist.
      _started = false;
      _logLoadFailure(error, stackTrace);
    }
  }

  void _logLoadFailure(Object error, StackTrace stackTrace) => logException(
    message: 'Plugins konnten nicht geladen werden.',
    error: error,
    stackTrace: stackTrace,
    name: 'plugins',
  );

  PluginManifest? manifestFor(String pluginId) {
    for (final manifest in state) {
      if (manifest.id == pluginId) return manifest;
    }
    return null;
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
