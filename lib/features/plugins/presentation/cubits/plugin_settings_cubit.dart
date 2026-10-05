import 'package:bloc/bloc.dart';

import '../../domain/usecases/plugin_use_cases.dart';
import 'plugin_settings_state.dart';

/// Einstellungs-Panels eines Plugins: laden, Entwurf bearbeiten, speichern.
class PluginSettingsCubit extends Cubit<PluginSettingsState> {
  PluginSettingsCubit(this._pluginId, this._load, this._save)
    : super(const PluginSettingsState());

  final String _pluginId;
  final LoadPluginSettings _load;
  final SavePluginSettings _save;

  Future<void> load() async {
    emit(const PluginSettingsState());
    final result = await _load(_pluginId);
    if (isClosed) return;
    result.when(
      (settings) => emit(
        PluginSettingsState(
          status: PluginSettingsStatus.ready,
          settings: settings,
        ),
      ),
      (failure) => emit(
        PluginSettingsState(
          status: PluginSettingsStatus.failure,
          message: failure.message,
        ),
      ),
    );
  }

  void setValue(String key, Object value) {
    emit(state.copyWith(draft: {...state.draft, key: value}));
  }

  Future<void> save() async {
    if (state.saving || !state.hasChanges) return;
    emit(state.copyWith(saving: true));
    final result = await _save(_pluginId, state.draft);
    if (isClosed) return;
    await result.when(
      (_) async {
        await load();
        if (!isClosed) emit(state.copyWith(message: 'Einstellungen gespeichert.'));
      },
      (failure) async =>
          emit(state.copyWith(saving: false, message: failure.message)),
    );
  }

  void messageShown() => emit(state.copyWith(clearMessage: true));
}
