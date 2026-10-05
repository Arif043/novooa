import 'package:equatable/equatable.dart';

import '../../domain/entities/plugin_catalog_entry.dart';

sealed class PluginInstallState extends Equatable {
  const PluginInstallState();

  @override
  List<Object?> get props => const [];
}

class PluginInstallIdle extends PluginInstallState {
  const PluginInstallIdle();
}

/// Das Paket wird vom Katalog geholt bzw. geprüft.
class PluginInstallChecking extends PluginInstallState {
  const PluginInstallChecking();
}

/// Das Paket ist geprüft; der Nutzer bestätigt oder bricht ab.
class PluginInstallReview extends PluginInstallState {
  const PluginInstallReview(this.preview);

  final PluginInstallPreview preview;

  @override
  List<Object?> get props => [preview];
}

class PluginInstallInstalling extends PluginInstallState {
  const PluginInstallInstalling(this.preview);

  final PluginInstallPreview preview;

  @override
  List<Object?> get props => [preview];
}

class PluginInstallDone extends PluginInstallState {
  const PluginInstallDone(this.name);

  final String name;

  @override
  List<Object?> get props => [name];
}

class PluginInstallFailed extends PluginInstallState {
  const PluginInstallFailed(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
