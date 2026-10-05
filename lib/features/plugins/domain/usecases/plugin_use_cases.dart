import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../entities/installed_plugin.dart';
import '../entities/plugin_catalog_entry.dart';
import '../entities/plugin_failure.dart';
import '../entities/plugin_settings.dart';
import '../repositories/plugin_install_repository.dart';
import '../repositories/plugin_repository.dart';

class WatchPlugins {
  const WatchPlugins(this._repository);

  final PluginRepository _repository;

  Stream<List<InstalledPlugin>> call(TeamId teamId) =>
      _repository.watchPlugins(teamId);
}

class UninstallPlugin {
  const UninstallPlugin(this._repository);

  final PluginRepository _repository;

  Future<Result<Unit, PluginFailure>> call(String pluginId) =>
      _repository.uninstall(pluginId);
}

class LoadPluginSettings {
  const LoadPluginSettings(this._repository);

  final PluginRepository _repository;

  Future<Result<PluginSettings, PluginFailure>> call(String pluginId) =>
      _repository.settings(pluginId);
}

class SavePluginSettings {
  const SavePluginSettings(this._repository);

  final PluginRepository _repository;

  Future<Result<Unit, PluginFailure>> call(
    String pluginId,
    Map<String, Object> values,
  ) => _repository.saveSettings(pluginId, values);
}

class LoadPluginCatalog {
  const LoadPluginCatalog(this._repository);

  final PluginInstallRepository _repository;

  Future<Result<List<PluginCatalogEntry>, PluginFailure>> call() =>
      _repository.catalog();
}

class PreviewPluginFromCatalog {
  const PreviewPluginFromCatalog(this._repository);

  final PluginInstallRepository _repository;

  Future<Result<PluginInstallPreview, PluginFailure>> call(String pluginId) =>
      _repository.previewFromCatalog(pluginId);
}

class PreviewPluginFromArchive {
  const PreviewPluginFromArchive(this._repository);

  final PluginInstallRepository _repository;

  Future<Result<PluginInstallPreview, PluginFailure>> call(
    Uint8List bytes,
    String fileName,
  ) => _repository.previewFromArchive(bytes, fileName);
}

class CommitPluginInstall {
  const CommitPluginInstall(this._repository);

  final PluginInstallRepository _repository;

  Future<Result<InstalledPlugin, PluginFailure>> call(String installId) =>
      _repository.commit(installId);
}
