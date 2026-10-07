import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_selection.dart';

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

  group('Filter-Chips', () {
    final piper = modelEntry(
      'piper',
      title: 'Piper',
      task: ModelTask.textToSpeech,
      languages: const ['de'],
    );
    final kokoro = modelEntry(
      'kokoro',
      title: 'Kokoro',
      task: ModelTask.textToSpeech,
      languages: const ['de', 'en'],
    );
    final detector = modelEntry(
      'detector',
      title: 'Detektor',
      task: ModelTask.objectDetection,
    );
    final models = [piper, kokoro, detector];
    const filter = ModelSearchFilter(languageTag: 'de');

    test('verknüpft Aufgabe und Sprachen', () {
      const selection = ModelSearchSelection(
        task: ModelTask.textToSpeech,
        languages: {'en', 'fr'},
      );

      expect(filter.apply(models, '', selection), [kokoro]);
    });

    test('zählt Treffer je Chip unter Berücksichtigung der anderen Gruppe', () {
      const selection = ModelSearchSelection(languages: {'en'});

      final facets = filter.facets(models, '', selection);

      expect(facets.tasks, {ModelTask.textToSpeech: 1});
      expect(facets.languages, {'de': 2, 'en': 1});
    });

    test('findet Aufgabe und Sprache auch über die Textsuche', () {
      expect(filter.apply(models, 'vorlesen englisch'), [kokoro]);
      expect(filter.apply(models, 'objekte'), [detector]);
    });

    test('legt bei Sprach-Bausteinen die Aufgabe fest', () {
      const speech = ModelSearchFilter(
        languageTag: 'de',
        speechDirection: SpeechModelDirection.textToSpeech,
      );

      expect(speech.fixedTask, ModelTask.textToSpeech);
      expect(speech.apply(models, ''), [piper, kokoro]);
    });

    test('ein erneuter Tipp hebt die Aufgabe wieder auf', () {
      const selection = ModelSearchSelection(task: ModelTask.translation);

      expect(selection.toggleTask(ModelTask.translation).isActive, isFalse);
      expect(
        selection.toggleLanguage('de').toggleLanguage('de').languages,
        isEmpty,
      );
    });
  });
}
