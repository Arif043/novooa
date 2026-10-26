import '../entities/model_tag_vocabulary.dart';
import '../repositories/model_tag_repository.dart';

class LoadModelTagVocabulary {
  const LoadModelTagVocabulary(this._repository);

  final ModelTagRepository _repository;

  Future<ModelTagVocabulary> call() => _repository.loadVocabulary();
}
