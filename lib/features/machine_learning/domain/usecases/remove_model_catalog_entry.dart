import '../repositories/model_catalog_repository.dart';

class RemoveModelCatalogEntry {
  const RemoveModelCatalogEntry(this._repository);

  final ModelCatalogRepository _repository;

  Future<void> call(String modelId) => _repository.removeEntry(modelId);
}
