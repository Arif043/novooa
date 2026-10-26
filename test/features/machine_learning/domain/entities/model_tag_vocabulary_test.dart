import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_tag_vocabulary.dart';

const vocabulary = ModelTagVocabulary([
  ModelTag(key: 'animals', labels: {'en': 'Animals', 'de': 'Tiere'}),
  ModelTag(
    key: 'pets',
    parent: 'animals',
    labels: {'en': 'Pets', 'de': 'Haustiere'},
    synonyms: {
      'de': ['Hund'],
    },
  ),
]);

void main() {
  test(
    'benennt Tags in der Sprache, sonst englisch, unbekannte als Schlüssel',
    () {
      expect(vocabulary.labelFor('pets', 'de-AT'), 'Haustiere');
      expect(vocabulary.labelFor('pets', 'tr'), 'Pets');
      expect(vocabulary.labelFor('rechnung', 'de'), 'rechnung');
    },
  );

  test('ordnet Tags ihrem Thema zu und ignoriert unbekannte Schlüssel', () {
    expect(vocabulary.topicsOf(['pets', 'rechnung']), {'animals'});
    expect(vocabulary.topicsOf(['animals']), {'animals'});
  });

  test('durchsucht Bezeichnungen und Synonyme samt Obertag', () {
    final texts = vocabulary.searchTextsFor(['pets']).toList();

    expect(texts, containsAll(['Haustiere', 'Hund', 'Tiere', 'animals']));
  });
}
