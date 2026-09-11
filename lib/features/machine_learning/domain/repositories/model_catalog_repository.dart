import '../entities/model_catalog_entry.dart';
import '../entities/model_catalog_import.dart';

abstract interface class ModelCatalogRepository {
  Stream<List<ModelCatalogEntry>> watchEntries();
  Future<void> importEntry(ModelCatalogImport value);
  Future<void> removeEntry(String modelId);
}
