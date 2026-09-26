import '../repositories/model_catalog_repository.dart';

class InstallGlobalModel {
  const InstallGlobalModel(this._repository);

  final GlobalModelCatalogRepository _repository;

  Future<void> call(String modelId) => _repository.installGlobalEntry(modelId);
}
