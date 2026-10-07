import '../entities/model_cache_status.dart';
import '../repositories/model_catalog_repository.dart';

class WatchModelCacheStatuses {
  const WatchModelCacheStatuses(this._repository);

  final GlobalModelCatalogRepository _repository;

  Stream<List<ModelCacheStatus>> call() => _repository.watchCacheStatuses();
}
