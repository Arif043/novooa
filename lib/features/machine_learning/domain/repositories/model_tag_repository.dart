import '../entities/model_tag_vocabulary.dart';

/// Das Tag-Vokabular der Runtime; offline ihr zuletzt gespiegelter Stand.
abstract interface class ModelTagRepository {
  Future<ModelTagVocabulary> loadVocabulary();
}
