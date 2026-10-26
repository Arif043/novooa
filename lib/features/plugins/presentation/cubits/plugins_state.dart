import '../../domain/entities/plugin_activation.dart';
import '../../domain/entities/plugin_failure.dart';

sealed class PluginsState {
  const PluginsState();

  /// Bis die Liste geladen ist, gilt jedes Plugin als aus.
  bool isEnabled(PluginId id) => false;
}

final class PluginsLoading extends PluginsState {
  const PluginsLoading();
}

final class PluginsLoadFailed extends PluginsState {
  const PluginsLoadFailed(this.failure);

  final PluginFailure failure;
}

final class PluginsLoaded extends PluginsState {
  const PluginsLoaded(this.enabledIds, {this.switchingId, this.notice});

  final Set<PluginId> enabledIds;

  /// Das Plugin, dessen Schalter gerade gesendet wird.
  final PluginId? switchingId;

  /// Einmalige Fehlermeldung für eine Snackbar.
  final PluginFailure? notice;

  @override
  bool isEnabled(PluginId id) => enabledIds.contains(id);
}
