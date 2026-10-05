import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';

import '../entities/installed_plugin.dart';
import '../entities/plugin_catalog_entry.dart';
import '../entities/plugin_failure.dart';

/// Katalog und Installation: erst prüfen (Vorschau), dann bestätigen.
abstract class PluginInstallRepository {
  Future<Result<List<PluginCatalogEntry>, PluginFailure>> catalog();

  Future<Result<PluginInstallPreview, PluginFailure>> previewFromCatalog(
    String pluginId,
  );

  Future<Result<PluginInstallPreview, PluginFailure>> previewFromArchive(
    Uint8List bytes,
    String fileName,
  );

  Future<Result<InstalledPlugin, PluginFailure>> commit(String installId);
}
