import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';

import 'model_catalog_test_support.dart';

void main() {
  final whisper = modelEntry(
    'whisper',
    title: 'Speech recognition',
    tags: ['audio'],
    translations: const {
      'de': ModelTranslation(
        title: 'Spracherkennung',
        description: 'Wandelt Sprache in Text um.',
        tags: ['transkription'],
      ),
    },
    inputs: const [
      ModelManifestInput(
        name: 'audio',
        source: ModelInputSource.audio,
        dataType: 'float32',
        shape: [1],
      ),
    ],
  );
  final classifier = modelEntry(
    'classifier',
    title: 'Bildklassifikation',
    description: 'Erkennt Objekte auf Fotos.',
  );

  test('sucht in deutschem Titel, Beschreibung und Schlagworten', () {
    const filter = ModelSearchFilter(languageTag: 'de-DE');

    expect(filter.apply([whisper, classifier], 'sprach'), [whisper]);
    expect(filter.apply([whisper, classifier], 'TRANSKRIPTION'), [whisper]);
    expect(filter.apply([whisper, classifier], 'objekte fotos'), [classifier]);
    expect(filter.apply([whisper, classifier], '  '), [whisper, classifier]);
  });

  test('bietet einem Sprache-zu-Text-Baustein nur Audio-Modelle an', () {
    const filter = ModelSearchFilter(
      languageTag: 'de',
      speechDirection: SpeechModelDirection.speechToText,
    );

    expect(filter.apply([whisper, classifier], ''), [whisper]);
  });
}
