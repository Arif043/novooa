import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/workspace_api_client.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/usecases/import_model_catalog_entry.dart';
import '../../domain/usecases/remove_model_catalog_entry.dart';
import '../../domain/usecases/watch_model_catalog_entries.dart';
import '../../domain/usecases/load_global_model_catalog.dart';
import '../../domain/usecases/install_global_model.dart';
import 'model_catalog_state.dart';

class ModelCatalogCubit extends Cubit<ModelCatalogState> {
  ModelCatalogCubit(
    this._watchEntries,
    this._importEntry,
    this._removeEntry, [
    this._loadGlobal,
    this._installGlobal,
  ]) : super(const ModelCatalogState());

  final WatchModelCatalogEntries _watchEntries;
  final ImportModelCatalogEntry _importEntry;
  final RemoveModelCatalogEntry _removeEntry;
  final LoadGlobalModelCatalog? _loadGlobal;
  final InstallGlobalModel? _installGlobal;
  StreamSubscription<List<ModelCatalogEntry>>? _subscription;

  void load() {
    _subscription?.cancel();
    emit(const ModelCatalogState());
    _subscription = _watchEntries().listen(
      (entries) => emit(
        state.copyWith(status: ModelCatalogStatus.ready, entries: entries),
      ),
      onError: (_, _) => emit(
        state.copyWith(
          status: ModelCatalogStatus.failure,
          message: 'Der Modellkatalog konnte nicht geladen werden.',
        ),
      ),
    );
  }

  Future<void> loadGlobal() async {
    final loader = _loadGlobal;
    if (loader == null) return;
    emit(state.copyWith(globalStatus: ModelCatalogStatus.loading));
    try {
      final entries = await loader();
      emit(
        state.copyWith(
          globalStatus: ModelCatalogStatus.ready,
          globalEntries: entries,
        ),
      );
    } on Object catch (_) {
      emit(state.copyWith(globalStatus: ModelCatalogStatus.failure));
    }
  }

  Future<void> installGlobalModel(String modelId) async {
    final installer = _installGlobal;
    if (installer == null) return;
    await _save(() => installer(modelId), 'Modell wurde installiert.');
  }

  Future<void> importModel(ModelCatalogImport value) async {
    await _save(() => _importEntry(value), 'Modell wurde importiert.');
  }

  Future<void> removeModel(String modelId) async {
    await _save(
      () => _removeEntry(modelId),
      'Modell wurde aus dem Katalog entfernt.',
    );
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(isSaving: false, message: success));
    } on WorkspaceHttpException catch (error) {
      emit(state.copyWith(isSaving: false, message: error.message));
    } on FormatException catch (error) {
      emit(state.copyWith(isSaving: false, message: error.message));
    } on Object catch (_) {
      emit(
        state.copyWith(
          isSaving: false,
          message: 'Der Modellkatalog konnte nicht aktualisiert werden.',
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
