import '../entities/model_cache_status.dart';
import '../entities/model_catalog_entry.dart';
import '../entities/model_catalog_import.dart';

abstract interface class ModelCatalogRepository {
  Stream<List<ModelCatalogEntry>> watchEntries();
  Future<void> importEntry(ModelCatalogImport value);
  Future<void> removeEntry(String modelId);
}

/// Globaler Modellkatalog als primäre Quelle; ausgewählte Modelle cacht die Runtime.
abstract interface class GlobalModelCatalogRepository {
  Future<List<ModelCatalogEntry>> loadGlobalEntries();

  /// Startet den Download im Hintergrund; der Fortschritt kommt über [watchCacheStatuses].
  Future<void> cacheGlobalEntry(String modelId);
  Stream<List<ModelCacheStatus>> watchCacheStatuses();
}
