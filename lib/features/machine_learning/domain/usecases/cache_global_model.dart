import '../repositories/model_catalog_repository.dart';

class CacheGlobalModel {
  const CacheGlobalModel(this._repository);

  final GlobalModelCatalogRepository _repository;

  Future<void> call(String modelId) => _repository.cacheGlobalEntry(modelId);
}
