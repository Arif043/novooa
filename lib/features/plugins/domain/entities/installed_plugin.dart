import 'package:equatable/equatable.dart';

import 'plugin_manifest.dart';

class InstalledPlugin extends Equatable {
  const InstalledPlugin({required this.manifest});

  final PluginManifest manifest;

  String get id => manifest.id;
  String get version => manifest.version;
  String get name => manifest.name;
  String get description => manifest.description;

  @override
  List<Object?> get props => [manifest];
}
