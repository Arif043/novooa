import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_cache_status.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_import.dart';
import 'package:syscat2/features/machine_learning/domain/repositories/model_catalog_repository.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/cache_global_model.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/import_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/load_global_model_catalog.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/remove_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/watch_model_cache_statuses.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/watch_model_catalog_entries.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';

class FakeModelCatalogRepository
    implements ModelCatalogRepository, GlobalModelCatalogRepository {
  List<ModelCatalogEntry> globalEntries = const [];
  Object? globalError;
  final cachedModelIds = <String>[];
  final entries = StreamController<List<ModelCatalogEntry>>.broadcast();
  final statuses = StreamController<List<ModelCacheStatus>>.broadcast();

  @override
  Future<List<ModelCatalogEntry>> loadGlobalEntries() async {
    if (globalError case final Object error) throw error;
    return globalEntries;
  }

  @override
  Future<void> cacheGlobalEntry(String modelId) async =>
      cachedModelIds.add(modelId);

  @override
  Stream<List<ModelCacheStatus>> watchCacheStatuses() => statuses.stream;

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() => entries.stream;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {}

  @override
  Future<void> removeEntry(String modelId) async {}
}

/// Cubit mit geladenem globalem Katalog und den lokalen Einträgen [local].
Future<ModelCatalogCubit> loadedCatalogCubit(
  WidgetTester tester,
  FakeModelCatalogRepository repository, {
  List<ModelCatalogEntry> local = const [],
}) async {
  final cubit = ModelCatalogCubit(
    WatchModelCatalogEntries(repository),
    ImportModelCatalogEntry(repository),
    RemoveModelCatalogEntry(repository),
    LoadGlobalModelCatalog(repository),
    CacheGlobalModel(repository),
    WatchModelCacheStatuses(repository),
  )..load();
  addTearDown(cubit.close);
  await tester.runAsync(() async {
    await cubit.loadGlobal();
    repository.entries.add(local);
    await Future<void>.delayed(Duration.zero);
  });
  return cubit;
}

Widget hostWithCatalog(ModelCatalogCubit cubit, Widget child) => MaterialApp(
  home: Scaffold(
    body: BlocProvider.value(value: cubit, child: child),
  ),
);

ModelCatalogEntry modelEntry(
  String id, {
  String title = 'Modell',
  String description = 'Ein Testmodell.',
  List<String> tags = const [],
  Map<String, ModelTranslation> translations = const {},
  List<ModelManifestInput> inputs = const [],
  List<ModelManifestOutput> outputs = const [],
  ModelOrigin? origin,
}) => ModelCatalogEntry(
  id: id,
  title: title,
  description: description,
  translations: translations,
  tags: tags,
  inputs: inputs,
  outputs: outputs,
  outputCount: outputs.length,
  sizeBytes: 2 * 1024 * 1024,
  origin: origin,
);
