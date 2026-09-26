import '../entities/model_catalog_entry.dart';
import '../entities/model_catalog_import.dart';

abstract interface class ModelCatalogRepository {
  Stream<List<ModelCatalogEntry>> watchEntries();
  Future<void> importEntry(ModelCatalogImport value);
  Future<void> removeEntry(String modelId);
}

abstract interface class GlobalModelCatalogRepository {
  Future<List<ModelCatalogEntry>> loadGlobalEntries();
  Future<void> installGlobalEntry(String modelId);
}
