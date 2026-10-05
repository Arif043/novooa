import 'dart:typed_data';

import 'package:multiple_result/multiple_result.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/core/network/workspace_binary_client.dart';

import '../../domain/entities/installed_plugin.dart';
import '../../domain/entities/plugin_catalog_entry.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/repositories/plugin_install_repository.dart';
import 'plugin_json_mapper.dart';

class LocalPluginInstallRepository implements PluginInstallRepository {
  const LocalPluginInstallRepository(this._client, this._binaryClient);

  final WorkspaceApiClient _client;
  final WorkspaceBinaryClient _binaryClient;

  @override
  Future<Result<List<PluginCatalogEntry>, PluginFailure>> catalog() =>
      _attempt(
        PluginFailure.catalogFailed,
        () async => catalogFromJson(await _client.get('/v1/plugins/catalog')),
      );

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromCatalog(
    String pluginId,
  ) => _attempt(
    PluginFailure.installFailed,
    () async => previewFromJson(
      await _client.post('/v1/plugins/installs/catalog', {'id': pluginId}),
    ),
  );

  @override
  Future<Result<PluginInstallPreview, PluginFailure>> previewFromArchive(
    Uint8List bytes,
    String fileName,
  ) => _attempt(
    PluginFailure.installFailed,
    () async => previewFromJson(
      await _binaryClient.postBytes(
        '/v1/plugins/installs/archive',
        body: bytes,
        contentType: 'application/zip',
      ),
    ),
  );

  @override
  Future<Result<InstalledPlugin, PluginFailure>> commit(String installId) =>
      _attempt(
        PluginFailure.installFailed,
        () async => pluginFromJson(
          await _client.post(
            '/v1/plugins/installs/${Uri.encodeComponent(installId)}/commit',
            const {},
          ),
        ),
      );

  Future<Result<T, PluginFailure>> _attempt<T extends Object>(
    PluginFailure fallback,
    Future<T> Function() action,
  ) async {
    try {
      return Success(await action());
    } on WorkspaceHttpException catch (error) {
      return Error(PluginFailure(error.message));
    } on Object {
      return Error(fallback);
    }
  }
}
