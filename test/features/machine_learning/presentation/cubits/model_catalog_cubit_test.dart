import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/core/network/workspace_api_client.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_import.dart';
import 'package:syscat2/features/machine_learning/domain/repositories/model_catalog_repository.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/import_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/remove_model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/usecases/watch_model_catalog_entries.dart';
import 'package:syscat2/features/machine_learning/presentation/cubits/model_catalog_cubit.dart';

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
}

ModelCatalogImport catalogImport() => ModelCatalogImport(
  manifestJson: '{}',
  artifactLength: 1,
  openArtifact: () => Stream.value([1]),
);

class _Repository implements ModelCatalogRepository {
  ModelCatalogImport? imported;
  Object? importError;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    if (importError case final Object error) throw error;
    imported = value;
  }

  @override
  Future<void> removeEntry(String modelId) async {}

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() => const Stream.empty();
}
