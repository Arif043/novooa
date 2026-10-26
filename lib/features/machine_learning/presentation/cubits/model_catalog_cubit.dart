import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/model_cache_status.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/usecases/cache_global_model.dart';
import '../../domain/usecases/import_model_catalog_entry.dart';
import '../../domain/usecases/load_global_model_catalog.dart';
import '../../domain/usecases/load_model_tag_vocabulary.dart';
import '../../domain/usecases/remove_model_catalog_entry.dart';
import '../../domain/usecases/watch_model_cache_statuses.dart';
import '../../domain/usecases/watch_model_catalog_entries.dart';
import 'model_catalog_state.dart';

class ModelCatalogCubit extends Cubit<ModelCatalogState> {
  ModelCatalogCubit(
    this._watchEntries,
    this._importEntry,
    this._removeEntry, [
    this._loadGlobal,
    this._cacheGlobal,
    this._watchCacheStatuses,
    this._loadTagVocabulary,
  ]) : super(const ModelCatalogState());

  final WatchModelCatalogEntries _watchEntries;
  final ImportModelCatalogEntry _importEntry;
  final RemoveModelCatalogEntry _removeEntry;
  final LoadGlobalModelCatalog? _loadGlobal;
  final CacheGlobalModel? _cacheGlobal;
  final WatchModelCacheStatuses? _watchCacheStatuses;
  final LoadModelTagVocabulary? _loadTagVocabulary;
  StreamSubscription<List<ModelCatalogEntry>>? _subscription;
  StreamSubscription<List<ModelCacheStatus>>? _cacheSubscription;

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
    _watchCache();
  }

  void _watchCache() {
    _cacheSubscription?.cancel();
    _cacheSubscription = _watchCacheStatuses?.call().listen(
      (statuses) => emit(
        state.copyWith(
          cacheStatuses: {
            for (final status in statuses) status.modelId: status,
          },
        ),
      ),
      // Ohne Status bleibt nur die Anzeige des Fortschritts aus; der Katalog funktioniert weiter.
      onError: (_, _) {},
    );
  }

  Future<void> loadGlobal() async {
    unawaited(_loadTags());
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

  /// Ohne Vokabular zeigen Suche und Treffer die Tag-Schlüssel; den Katalogfehler meldet [loadGlobal].
  Future<void> _loadTags() async {
    final loader = _loadTagVocabulary;
    if (loader == null) return;
    try {
      final vocabulary = await loader();
      if (!isClosed) emit(state.copyWith(tagVocabulary: vocabulary));
    } on Object catch (_) {}
  }

  /// Lässt die Runtime ein Katalogmodell im Hintergrund laden; ohne Wirkung, wenn es schon lokal ist.
  Future<void> cacheModel(String modelId) async {
    final cache = _cacheGlobal;
    if (cache == null || state.localEntry(modelId) != null) return;
    _setCacheStatus(
      ModelCacheStatus(modelId: modelId, state: ModelCacheState.downloading),
    );
    try {
      await cache(modelId);
    } on Object catch (error) {
      _setCacheStatus(
        ModelCacheStatus(
          modelId: modelId,
          state: ModelCacheState.failed,
          message: _messageOf(error),
        ),
      );
    }
  }

  void _setCacheStatus(ModelCacheStatus status) {
    emit(
      state.copyWith(
        cacheStatuses: {...state.cacheStatuses, status.modelId: status},
      ),
    );
  }

  Future<void> importModel(ModelCatalogImport value) async {
    await _save(() => _importEntry(value), 'Modell wurde importiert.');
  }

  Future<void> removeModel(String modelId) async {
    await _save(() => _removeEntry(modelId), 'Modell wurde entfernt.');
  }

  Future<void> _save(Future<void> Function() action, String success) async {
    emit(state.copyWith(isSaving: true, clearMessage: true));
    try {
      await action();
      emit(state.copyWith(isSaving: false, message: success));
    } on Object catch (error) {
      emit(state.copyWith(isSaving: false, message: _messageOf(error)));
    }
  }

  String _messageOf(Object error) => switch (error) {
    WorkspaceHttpException(:final message) => message,
    FormatException(:final message) => message,
    _ => 'Der Modellkatalog konnte nicht aktualisiert werden.',
  };

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _cacheSubscription?.cancel();
    return super.close();
  }
}
