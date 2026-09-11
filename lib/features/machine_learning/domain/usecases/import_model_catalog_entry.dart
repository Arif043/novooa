import '../entities/model_catalog_import.dart';
import '../repositories/model_catalog_repository.dart';

class ImportModelCatalogEntry {
  const ImportModelCatalogEntry(this._repository);

  final ModelCatalogRepository _repository;

  Future<void> call(ModelCatalogImport value) => _repository.importEntry(value);
}
