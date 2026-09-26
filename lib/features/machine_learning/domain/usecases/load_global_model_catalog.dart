import '../entities/model_catalog_entry.dart';
import '../repositories/model_catalog_repository.dart';

class LoadGlobalModelCatalog {
  const LoadGlobalModelCatalog(this._repository);

  final GlobalModelCatalogRepository _repository;

  Future<List<ModelCatalogEntry>> call() => _repository.loadGlobalEntries();
}
