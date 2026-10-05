import 'package:bloc/bloc.dart';
import 'package:multiple_result/multiple_result.dart';

import '../../domain/entities/plugin_catalog_entry.dart';
import '../../domain/entities/plugin_failure.dart';
import '../../domain/repositories/plugin_archive_gateway.dart';
import '../../domain/usecases/plugin_use_cases.dart';
import 'plugin_install_state.dart';

/// Installation in zwei Schritten: Paket prüfen (Vorschau), dann bestätigen.
class PluginInstallCubit extends Cubit<PluginInstallState> {
  PluginInstallCubit(
    this._previewFromCatalog,
    this._previewFromArchive,
    this._commit,
    this._archives,
  ) : super(const PluginInstallIdle());

  final PreviewPluginFromCatalog _previewFromCatalog;
  final PreviewPluginFromArchive _previewFromArchive;
  final CommitPluginInstall _commit;
  final PluginArchiveGateway _archives;

  Future<void> previewCatalogEntry(String pluginId) async {
    emit(const PluginInstallChecking());
    _emitPreview(await _previewFromCatalog(pluginId));
  }

  Future<void> pickArchive() async {
    final picked = await _archives.pick();
    if (isClosed) return;
    final archive = picked.tryGetSuccess();
    if (archive == null) {
      final failure = picked.tryGetError();
      // Abbrechen ist kein Fehler: der Dialog bleibt, wie er war.
      if (failure != null && !failure.isCancelled) {
        emit(PluginInstallFailed(failure.message));
      }
      return;
    }
    emit(const PluginInstallChecking());
    _emitPreview(await _previewFromArchive(archive.bytes, archive.fileName));
  }

  Future<void> confirm() async {
    final current = state;
    if (current is! PluginInstallReview) return;
    emit(PluginInstallInstalling(current.preview));
    final result = await _commit(current.preview.installId);
    if (isClosed) return;
    result.when(
      (plugin) => emit(PluginInstallDone(plugin.name)),
      (failure) => emit(PluginInstallFailed(failure.message)),
    );
  }

  void reset() => emit(const PluginInstallIdle());

  void _emitPreview(Result<PluginInstallPreview, PluginFailure> result) {
    if (isClosed) return;
    result.when(
      (preview) => emit(PluginInstallReview(preview)),
      (failure) => emit(PluginInstallFailed(failure.message)),
    );
  }
}
