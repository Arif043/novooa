import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_catalog_entry.dart';
import 'package:syscat2/features/machine_learning/domain/entities/model_tag_vocabulary.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_filter.dart';
import 'package:syscat2/features/task_builder/presentation/widgets/model_inference/model_search_selection.dart';

import 'model_catalog_test_support.dart';

const vocabulary = ModelTagVocabulary([
  ModelTag(
    key: 'transcription',
    labels: {'en': 'Transcription', 'de': 'Transkription'},
  ),
  ModelTag(key: 'animals', labels: {'en': 'Animals', 'de': 'Tiere'}),
  ModelTag(
    key: 'pets',
    parent: 'animals',
    labels: {'en': 'Pets', 'de': 'Haustiere'},
    synonyms: {
      'de': ['Hund'],
    },
  ),
  ModelTag(key: 'documents', labels: {'en': 'Documents', 'de': 'Dokumente'}),
]);

void main() {
  final whisper = modelEntry(
    'whisper',
    title: 'Speech recognition',
    tags: ['transcription'],
    translations: const {
      'de': ModelTranslation(
        title: 'Spracherkennung',
        description: 'Wandelt Sprache in Text um.',
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
    const filter = ModelSearchFilter(
      languageTag: 'de-DE',
      vocabulary: vocabulary,
    );

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

  group('Themen', () {
    final dogs = modelEntry('dogs', title: 'Hunderassen', tags: ['pets']);
    final birds = modelEntry('birds', title: 'Vögel', tags: ['animals']);
    final scans = modelEntry('scans', title: 'Scans', tags: ['documents']);
    final legacy = modelEntry('legacy', title: 'Alt', tags: ['rechnung']);
    const filter = ModelSearchFilter(languageTag: 'de', vocabulary: vocabulary);

    test('findet ein Modell über sein Thema, den Obertag und Synonyme', () {
      expect(filter.apply([dogs, scans], 'haustiere'), [dogs]);
      expect(filter.apply([dogs, birds, scans], 'tiere'), [dogs, birds]);
      expect(filter.apply([dogs, scans], 'animals'), [dogs]);
    });

    test('zählt Obertags als Themen, unbekannte Freitext-Tags nicht', () {
      final facets = filter.facets(
        [dogs, birds, scans, legacy],
        '',
        const ModelSearchSelection(),
      );

      expect(facets.topics, {'animals': 2, 'documents': 1});
    });

    test('grenzt auf ein Thema ein, Untertags eingeschlossen', () {
      const selection = ModelSearchSelection(topic: 'animals');

      expect(filter.apply([dogs, birds, scans], '', selection), [dogs, birds]);
      expect(selection.toggleTopic('animals').isActive, isFalse);
      expect(selection.toggleTask(ModelTask.other).topic, 'animals');
    });
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
      const selection = ModelSearchSelection(
        task: ModelTask.textClassification,
      );

      expect(
        selection.toggleTask(ModelTask.textClassification).isActive,
        isFalse,
      );
      expect(
        selection.toggleLanguage('de').toggleLanguage('de').languages,
        isEmpty,
      );
    });
  });

  group('Bereiche', () {
    final ocr = modelEntry('ocr', task: ModelTask.opticalCharacterRecognition);
    final yolo = modelEntry('yolo', task: ModelTask.objectDetection);
    final whisper = modelEntry(
      'whisper',
      task: ModelTask.automaticSpeechRecognition,
      languages: const ['de'],
    );
    final models = [ocr, yolo, whisper];
    const filter = ModelSearchFilter(languageTag: 'de');

    test('ordnet jede Aufgabe genau einem Bereich zu', () {
      for (final task in ModelTask.values) {
        expect(ModelTaskArea.values, contains(task.area));
      }
      expect(ModelTask.fromKey('anomaly-detection').area, ModelTaskArea.data);
    });

    test('grenzt nach Bereich ein und zählt Aufgaben nur darin', () {
      const selection = ModelSearchSelection(area: ModelTaskArea.imageVideo);

      expect(filter.apply(models, '', selection), [ocr, yolo]);
      final facets = filter.facets(models, '', selection);
      expect(facets.areas, {
        ModelTaskArea.imageVideo: 2,
        ModelTaskArea.audio: 1,
      });
      expect(facets.tasks.keys, [
        ModelTask.opticalCharacterRecognition,
        ModelTask.objectDetection,
      ]);
    });

    test('ein Bereichswechsel verwirft eine fremde Aufgabe', () {
      const selection = ModelSearchSelection(task: ModelTask.objectDetection);

      expect(
        selection.toggleArea(ModelTaskArea.imageVideo).task,
        ModelTask.objectDetection,
      );
      expect(selection.toggleArea(ModelTaskArea.audio).task, isNull);
    });

    test('findet Modelle über den Bereichsnamen', () {
      expect(filter.apply(models, 'audio'), [whisper]);
    });
  });
}
