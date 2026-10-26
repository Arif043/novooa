import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_cache_status.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_import.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_tag_vocabulary.dart';
import 'package:syscat2/features/machine_learning/domain/repositories/model_tag_repository.dart';
import 'package:syscat2/features/machine_learning/domain/repositories/model_catalog_repository.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/import_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/cache_global_model.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/load_global_model_catalog.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/load_model_tag_vocabulary.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/remove_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/watch_model_cache_statuses.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/watch_model_catalog_entries.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_state.dart';

void main() {
  test('imports a model through the catalog use case', () async {
    final repository = _Repository();
    final cubit = ModelCatalogCubit(
      WatchModelCatalogEntries(repository),
      ImportModelCatalogEntry(repository),
      RemoveModelCatalogEntry(repository),
    );

    await cubit.importModel(catalogImport());

    expect(repository.imported, isNotNull);
    expect(cubit.state.message, 'Modell wurde importiert.');
    await cubit.close();
  });

  test(
    'shows the local runtime validation message for an invalid import',
    () async {
      final repository = _Repository()
        ..importError = WorkspaceHttpException(
          400,
          const WorkspaceApiError(
            message: 'Diese lokale Modellversion ist bereits installiert.',
          ),
        );
      final cubit = ModelCatalogCubit(
        WatchModelCatalogEntries(repository),
        ImportModelCatalogEntry(repository),
        RemoveModelCatalogEntry(repository),
      );

      await cubit.importModel(catalogImport());

      expect(
        cubit.state.message,
        'Diese lokale Modellversion ist bereits installiert.',
      );
      await cubit.close();
    },
  );

  test('caches a selected catalog model and follows its status', () async {
    final repository = _Repository()..globalEntries = [catalogEntry()];
    final cubit = _cacheCubit(repository);
    cubit.load();

    await cubit.loadGlobal();
    await cubit.cacheModel('system-model');

    expect(cubit.state.globalEntries, [catalogEntry()]);
    expect(repository.cachedModelIds, ['system-model']);
    expect(
      cubit.state.cacheStatuses['system-model']?.state,
      ModelCacheState.downloading,
    );
    repository.statuses.add(const []);
    repository.entries.add([cachedEntry()]);
    await pumpEventQueue();
    expect(cubit.state.cacheStatuses, isEmpty);
    expect(cubit.state.cachedEntries, [cachedEntry()]);
    expect(cubit.state.selectableEntries, [cachedEntry()]);
    await cubit.close();
  });

  test('does not download a model that is already local', () async {
    final repository = _Repository();
    final cubit = _cacheCubit(repository)..load();
    repository.entries.add([cachedEntry()]);
    await pumpEventQueue();

    await cubit.cacheModel('system-model');

    expect(repository.cachedModelIds, isEmpty);
    await cubit.close();
  });

  test('shows a failed download with the runtime message', () async {
    final repository = _Repository()
      ..cacheError = WorkspaceHttpException(
        503,
        const WorkspaceApiError(
          message: 'Der globale Modellkatalog ist nicht verfügbar.',
        ),
      );
    final cubit = _cacheCubit(repository);

    await cubit.cacheModel('system-model');

    expect(
      cubit.state.cacheStatuses['system-model'],
      const ModelCacheStatus(
        modelId: 'system-model',
        state: ModelCacheState.failed,
        message: 'Der globale Modellkatalog ist nicht verfügbar.',
      ),
    );
    await cubit.close();
  });

  test('lädt mit dem globalen Katalog das Tag-Vokabular', () async {
    final repository = _Repository()..globalEntries = [catalogEntry()];
    final cubit = _cacheCubit(repository, _Tags(_animals));

    await cubit.loadGlobal();
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tagVocabulary, _animals);
    expect(cubit.state.globalEntries, [catalogEntry()]);
    await cubit.close();
  });

  test(
    'bleibt ohne Vokabular nutzbar, wenn es nicht geladen werden kann',
    () async {
      final repository = _Repository()..globalEntries = [catalogEntry()];
      final cubit = _cacheCubit(repository, _Tags(null));

      await cubit.loadGlobal();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.tagVocabulary, ModelTagVocabulary.empty);
      expect(cubit.state.globalStatus, ModelCatalogStatus.ready);
      await cubit.close();
    },
  );
}

const _animals = ModelTagVocabulary([
  ModelTag(key: 'animals', labels: {'en': 'Animals'}),
]);

class _Tags implements ModelTagRepository {
  _Tags(this.vocabulary);

  /// `null` lässt das Laden scheitern.
  final ModelTagVocabulary? vocabulary;

  @override
  Future<ModelTagVocabulary> loadVocabulary() async =>
      vocabulary ?? (throw StateError('offline'));
}

ModelCatalogCubit _cacheCubit(_Repository repository, [_Tags? tags]) =>
    ModelCatalogCubit(
      WatchModelCatalogEntries(repository),
      ImportModelCatalogEntry(repository),
      RemoveModelCatalogEntry(repository),
      LoadGlobalModelCatalog(repository),
      CacheGlobalModel(repository),
      WatchModelCacheStatuses(repository),
      tags == null ? null : LoadModelTagVocabulary(tags),
    );

ModelCatalogEntry cachedEntry() => const ModelCatalogEntry(
  id: 'system-model',
  title: 'Systemmodell',
  description: 'Ein Modell aus dem globalen Katalog.',
  tags: ['test'],
  inputs: [],
  outputs: [],
  outputCount: 0,
  sizeBytes: 4,
  origin: ModelOrigin.catalog,
);

ModelCatalogImport catalogImport() => ModelCatalogImport(
  manifestJson: '{}',
  artifactLength: 1,
  openArtifact: () => Stream.value([1]),
);

ModelCatalogEntry catalogEntry() => const ModelCatalogEntry(
  id: 'system-model',
  title: 'Systemmodell',
  description: 'Ein Modell aus dem globalen Katalog.',
  tags: ['test'],
  inputs: [],
  outputs: [],
  outputCount: 0,
  sizeBytes: 4,
);

class _Repository
    implements ModelCatalogRepository, GlobalModelCatalogRepository {
  ModelCatalogImport? imported;
  Object? importError;
  List<ModelCatalogEntry> globalEntries = const [];
  final cachedModelIds = <String>[];
  Object? cacheError;
  final entries = StreamController<List<ModelCatalogEntry>>.broadcast();
  final statuses = StreamController<List<ModelCacheStatus>>.broadcast();

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    if (importError case final Object error) throw error;
    imported = value;
  }

  @override
  Future<void> removeEntry(String modelId) async {}

  @override
  Future<void> cacheGlobalEntry(String modelId) async {
    if (cacheError case final Object error) throw error;
    cachedModelIds.add(modelId);
  }

  @override
  Stream<List<ModelCacheStatus>> watchCacheStatuses() => statuses.stream;

  @override
  Future<List<ModelCatalogEntry>> loadGlobalEntries() async => globalEntries;

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() => entries.stream;
}
