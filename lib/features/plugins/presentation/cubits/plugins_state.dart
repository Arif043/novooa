import 'package:equatable/equatable.dart';

import '../../domain/entities/installed_plugin.dart';

enum PluginsStatus { loading, ready, failure }

class PluginsState extends Equatable {
  const PluginsState({
    this.status = PluginsStatus.loading,
    this.plugins = const [],
    this.message,
  });

  final PluginsStatus status;
  final List<InstalledPlugin> plugins;

  /// Einmalige Rückmeldung (Fehler oder Bestätigung) für eine Snackbar.
  final String? message;

  PluginsState copyWith({
    PluginsStatus? status,
    List<InstalledPlugin>? plugins,
    String? message,
    bool clearMessage = false,
  }) {
    return PluginsState(
      status: status ?? this.status,
      plugins: plugins ?? this.plugins,
      message: clearMessage ? null : message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, plugins, message];
}
