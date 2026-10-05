import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/features/files/domain/entities/team_id.dart';

import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_catalog_entry.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/entities/plugin_settings.dart';
import '../../domain/repositories/plugin_install_repository.dart';
import '../../domain/repositories/plugin_repository.dart';

const _unavailable = PluginFailure(
  'Plugins sind in dieser Betriebsvariante noch nicht verfügbar.',
);

/// Für Betriebsvarianten ohne Plugin-Speicher (Cloud, bis dort umgesetzt).
class UnavailablePluginRepository implements PluginRepository {
  const UnavailablePluginRepository();

  @override
  Stream<List<InstalledPlugin>> watchPlugins(TeamId teamId) =>
      Stream.value(const []);

  @override
  Future<Result<Unit, PluginFailure>> uninstall(String pluginId) async =>
      const Error(_unavailable);

  @override
  Future<Result<PluginSettings, PluginFailure>> settings(
    String pluginId,
  ) async => const Error(_unavailable);

  @override
  Future<Result<Unit, PluginFailure>> saveSettings(
    String pluginId,
    Map<String, Object> values,
  ) async => const Error(_unavailable);
}

class UnavailablePluginInstallRepository implements PluginInstallRepository {
  const UnavailablePluginInstallRepository();

  @override
  Future<Result<List<PluginCatalogEntry>, PluginFailure>> catalog() async =>
      const Error(_unavailable);

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromCatalog(
    String pluginId,
  ) async => const Error(_unavailable);

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromArchive(
    Uint8List bytes,
    String fileName,
  ) async => const Error(_unavailable);

  @override
  Future<Result<InstalledPlugin, PluginFailure>> commit(
    String installId,
  ) async => const Error(_unavailable);
}
