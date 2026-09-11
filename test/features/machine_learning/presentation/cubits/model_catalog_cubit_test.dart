import 'package:flutter_test/flutter_test.dart';
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

    await cubit.importModel(
      const ModelCatalogImport(manifestJson: '{}', artifactBytes: [1]),
    );

    expect(repository.imported, isNotNull);
    expect(cubit.state.message, 'Modell wurde importiert.');
    await cubit.close();
  });
}

class _Repository implements ModelCatalogRepository {
  ModelCatalogImport? imported;

  @override
  Future<void> importEntry(ModelCatalogImport value) async {
    imported = value;
  }

  @override
  Future<void> removeEntry(String modelId) async {}

  @override
  Stream<List<ModelCatalogEntry>> watchEntries() => const Stream.empty();
}
