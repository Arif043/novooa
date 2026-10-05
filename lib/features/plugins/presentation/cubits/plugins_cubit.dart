import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:syscat2/core/logging/logger.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';
import 'package:syscat2/features/teams/domain/usecases/get_current_team_id.dart';

import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/usecases/plugin_use_cases.dart';
import 'plugins_state.dart';

/// Zeigt die installierten Plugins und deinstalliert sie. Neue Plugins kommen
/// über die Installation ([PluginInstallCubit]); Änderungen meldet die Runtime
/// per Realtime-Kanal.
class PluginsCubit extends Cubit<PluginsState> {
  PluginsCubit(this._watchPlugins, this._uninstallPlugin, this._getCurrentTeamId)
    : super(const PluginsState());

  final WatchPlugins _watchPlugins;
  final UninstallPlugin _uninstallPlugin;
  final GetCurrentTeamId _getCurrentTeamId;
  StreamSubscription<List<InstalledPlugin>>? _subscription;

  Future<void> load() async {
    emit(const PluginsState());
    await _subscription?.cancel();
    final teamId = await _teamIdOrNull();
    if (teamId == null) return;
    _subscription = _watchPlugins(teamId).listen(
      _emitPlugins,
      onError: (Object error, StackTrace stackTrace) {
        logException(
          message: 'Plugins konnten nicht geladen werden.',
          error: error,
          stackTrace: stackTrace,
          name: 'plugins',
        );
        _emitFailure(PluginFailure.loadFailed.message);
      },
    );
  }

  Future<void> uninstall(String pluginId) async {
    final name = state.plugins
        .where((plugin) => plugin.id == pluginId)
        .map((plugin) => plugin.name)
        .firstOrNull;
    final result = await _uninstallPlugin(pluginId);
    if (isClosed) return;
    result.when(
      (_) => emit(
        state.copyWith(message: 'Plugin „${name ?? pluginId}“ deinstalliert.'),
      ),
      (failure) => emit(state.copyWith(message: failure.message)),
    );
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));

  Future<TeamId?> _teamIdOrNull() async {
    try {
      return await _getCurrentTeamId();
    } catch (error, stackTrace) {
      logException(
        message: 'Team konnte nicht geladen werden.',
        error: error,
        stackTrace: stackTrace,
        name: 'plugins',
      );
      _emitFailure('Team konnte nicht geladen werden.');
      return null;
    }
  }

  void _emitPlugins(List<InstalledPlugin> plugins) {
    if (isClosed) return;
    emit(state.copyWith(status: PluginsStatus.ready, plugins: plugins));
  }

  void _emitFailure(String message) {
    if (isClosed) return;
    emit(state.copyWith(status: PluginsStatus.failure, message: message));
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
