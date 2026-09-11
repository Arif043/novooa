import '../entities/model_catalog_entry.dart';
import '../repositories/model_catalog_repository.dart';

class WatchModelCatalogEntries {
  const WatchModelCatalogEntries(this._repository);

  final ModelCatalogRepository _repository;

  Stream<List<ModelCatalogEntry>> call() => _repository.watchEntries();
}
