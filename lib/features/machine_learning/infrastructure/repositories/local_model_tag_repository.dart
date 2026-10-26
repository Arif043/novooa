import 'package:novooa_runtime_client/novooa_runtime_client.dart';

import '../../domain/entities/model_tag_vocabulary.dart';
import '../../domain/repositories/model_tag_repository.dart';
import '../mappers/model_tag_mapper.dart';

class LocalModelTagRepository implements ModelTagRepository {
  const LocalModelTagRepository(
    this._client, [
    this._mapper = const ModelTagMapper(),
  ]);

  final WorkspaceApiClient _client;
  final ModelTagMapper _mapper;

  @override
  Future<ModelTagVocabulary> loadVocabulary() async {
    final response = await _client.get('/v1/ml-models/tags');
    final items = response['items'];
    if (items is! List) {
      throw const FormatException('Das Tag-Vokabular ist ungültig.');
    }
    return _mapper.vocabularyFrom(items);
  }
}
