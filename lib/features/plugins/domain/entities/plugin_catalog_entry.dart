import 'package:equatable/equatable.dart';

import 'plugin_manifest.dart';

/// Ein vom Admin veröffentlichtes Plugin, das ein Team installieren kann.
class PluginCatalogEntry extends Equatable {
  const PluginCatalogEntry({
    required this.id,
    required this.name,
    required this.description,
    required this.version,
    required this.sizeBytes,
  });

  final String id;
  final String name;
  final String description;
  final String version;
  final int sizeBytes;

  @override
  List<Object?> get props => [id, name, description, version, sizeBytes];
}

/// Das geprüfte, noch nicht installierte Paket — der Nutzer bestätigt erst nach der Vorschau.
class PluginInstallPreview extends Equatable {
  const PluginInstallPreview({
    required this.installId,
    required this.manifest,
    this.installedVersion,
  });

  final String installId;
  final PluginManifest manifest;

  /// Gesetzt, wenn das Plugin bereits installiert ist und ersetzt würde.
  final String? installedVersion;

  bool get isUpdate => installedVersion != null;

  @override
  List<Object?> get props => [installId, manifest, installedVersion];
}
