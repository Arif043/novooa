import 'package:equatable/equatable.dart';

import '../../domain/entities/plugin_settings.dart';

enum PluginSettingsStatus { loading, ready, failure }

class PluginSettingsState extends Equatable {
  const PluginSettingsState({
    this.status = PluginSettingsStatus.loading,
    this.settings = const PluginSettings(),
    this.draft = const {},
    this.saving = false,
    this.message,
  });

  final PluginSettingsStatus status;

  /// Zuletzt gespeicherter Stand.
  final PluginSettings settings;

  /// Geänderte, noch nicht gespeicherte Werte (Geheimnisse nur, wenn neu eingegeben).
  final Map<String, Object> draft;
  final bool saving;
  final String? message;

  bool get hasChanges => draft.isNotEmpty;

  /// Aktueller Wert eines Feldes: Entwurf vor gespeichertem Wert.
  Object? valueOf(String key) => draft[key] ?? settings.values[key];

  PluginSettingsState copyWith({
    PluginSettingsStatus? status,
    PluginSettings? settings,
    Map<String, Object>? draft,
    bool? saving,
    String? message,
    bool clearMessage = false,
  }) {
    return PluginSettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      draft: draft ?? this.draft,
      saving: saving ?? this.saving,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, settings, draft, saving, message];
}
