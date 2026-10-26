import 'dart:async';

import 'package:bloc/bloc.dart';

import '../../domain/entities/plugin_activation.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/usecases/set_plugin_enabled.dart';
import '../../domain/usecases/watch_plugins.dart';
import 'plugins_state.dart';

/// App-weit: Palette, Leinwand, Auslöser und Einstellungen sehen denselben
/// Stand der Plugins.
class PluginsCubit extends Cubit<PluginsState> {
  PluginsCubit(this._watchPlugins, this._setPluginEnabled)
    : super(const PluginsLoading());

  final WatchPlugins _watchPlugins;
  final SetPluginEnabled _setPluginEnabled;
  StreamSubscription<List<PluginActivation>>? _subscription;

  void start() {
    unawaited(_subscription?.cancel());
    emit(const PluginsLoading());
    _subscription = _watchPlugins().listen(
      (plugins) => emit(PluginsLoaded(_enabledIn(plugins))),
      onError: (Object error) => emit(
        PluginsLoadFailed(
          error is PluginFailure
              ? error
              : const PluginFailure(PluginFailureKind.unexpected),
        ),
      ),
    );
  }

  Future<void> setEnabled(PluginId id, {required bool enabled}) async {
    final loaded = state;
    if (loaded is! PluginsLoaded || loaded.switchingId != null) return;
    emit(PluginsLoaded(loaded.enabledIds, switchingId: id));
    final activationOrFailure = await _setPluginEnabled(id, enabled: enabled);
    if (isClosed) return;
    activationOrFailure.when(
      (activation) => emit(PluginsLoaded(_switched(loaded, activation))),
      (failure) => emit(PluginsLoaded(loaded.enabledIds, notice: failure)),
    );
  }

  Set<PluginId> _enabledIn(List<PluginActivation> plugins) => {
    for (final plugin in plugins)
      if (plugin.isEnabled) plugin.id,
  };

  /// Sofort sichtbar; das Echtzeit-Thema bestätigt kurz danach.
  Set<PluginId> _switched(PluginsLoaded loaded, PluginActivation activation) {
    final enabledIds = {...loaded.enabledIds};
    if (activation.isEnabled) return enabledIds..add(activation.id);
    return enabledIds..remove(activation.id);
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
