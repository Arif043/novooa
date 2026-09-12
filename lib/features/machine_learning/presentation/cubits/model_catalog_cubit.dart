import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/local_runtime_api_client.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_catalog_import.dart';
import '../../domain/usecases/import_model_catalog_entry.dart';
import '../../domain/usecases/remove_model_catalog_entry.dart';
import '../../domain/usecases/watch_model_catalog_entries.dart';
import 'model_catalog_state.dart';

class ModelCatalogCubit extends Cubit<ModelCatalogState> {
  ModelCatalogCubit(this._watchEntries, this._importEntry, this._removeEntry)
    : super(const ModelCatalogState());

  final WatchModelCatalogEntries _watchEntries;
  final ImportModelCatalogEntry _importEntry;
  final RemoveModelCatalogEntry _removeEntry;
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
    } on LocalRuntimeHttpException catch (error) {
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
