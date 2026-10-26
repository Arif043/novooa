import 'package:flutter_test/flutter_test.dart';
import 'package:novooa_runtime_client/novooa_runtime_client.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_tag_vocabulary.dart';
import 'package:syscat2/features/machine_learning/infrastructure/repositories/local_model_tag_repository.dart';

void main() {
  test(
    'liest das Tag-Vokabular der Runtime samt Obertag und Synonymen',
    () async {
      final client = _Client({
        'items': [
          {
            'key': 'animals',
            'labels': {'en': 'Animals', 'de': 'Tiere'},
            'synonyms': <String, Object?>{},
          },
          {
            'key': 'pets',
            'parent': 'animals',
            'labels': {'en': 'Pets'},
            'synonyms': {
              'de': ['Hund'],
            },
          },
        ],
      });

      final vocabulary = await LocalModelTagRepository(client).loadVocabulary();

      expect(client.requestedPath, '/v1/ml-models/tags');
      expect(vocabulary.tags.last, isA<ModelTag>());
      expect(vocabulary.topicsOf(['pets']), {'animals'});
      expect(vocabulary.searchTextsFor(['pets']), contains('Hund'));
    },
  );

  test('lehnt eine Antwort ohne Liste ab', () async {
    expect(
      LocalModelTagRepository(_Client({'items': 'kaputt'})).loadVocabulary(),
      throwsFormatException,
    );
  });
}

class _Client extends WorkspaceApiClient {
  _Client(this.response);

  final Map<String, Object?> response;
  String? requestedPath;

  @override
  Future<Map<String, Object?>> get(String path) async {
    requestedPath = path;
    return response;
  }

  @override
  Future<Map<String, Object?>> delete(String path) async => const {};

  @override
  Future<Map<String, Object?>> post(
    String path,
    Map<String, Object?> body,
  ) async => const {};

  @override
  Future<Map<String, Object?>> put(
    String path,
    Map<String, Object?> body,
  ) async => const {};
}
