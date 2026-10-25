import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_provider.dart';
import 'package:syscat2/features/language_models/presentation/widgets/language_model_provider_logo.dart';

void main() {
  group('Abacus.AI und Hugging Face', () {
    test(
      'sind eigene Anbieter mit festem Endpunkt und nicht der generische OpenAI-Modus',
      () {
        expect(LanguageModelProvider.abacus.label, 'Abacus.AI (RouteLLM)');
        expect(
          LanguageModelProvider.abacus.defaultBaseUrl,
          'https://routellm.abacus.ai/v1',
        );
        expect(LanguageModelProvider.huggingFace.label, 'Hugging Face');
        expect(
          LanguageModelProvider.huggingFace.defaultBaseUrl,
          'https://router.huggingface.co/v1',
        );
        for (final provider in [
          LanguageModelProvider.abacus,
          LanguageModelProvider.huggingFace,
        ]) {
          expect(provider.isDirectProvider, isTrue);
          expect(provider.requiresCustomBaseUrl, isFalse);
          expect(provider, isNot(LanguageModelProvider.openAiCompatible));
        }
      },
    );

    test('lassen sich über ihre ID wiederfinden', () {
      expect(
        LanguageModelProvider.fromId('abacus'),
        LanguageModelProvider.abacus,
      );
      expect(
        LanguageModelProvider.fromId('huggingFace'),
        LanguageModelProvider.huggingFace,
      );
      expect(
        LanguageModelProvider.tryFromId('huggingFace'),
        LanguageModelProvider.huggingFace,
      );
    });

    test(
      'sind getrennt vom generischen OpenAI-kompatiblen Anbieter aufgelistet',
      () {
        final labels = LanguageModelProvider.values
            .map((provider) => provider.label)
            .toList();

        expect(
          labels,
          containsAll([
            'Abacus.AI (RouteLLM)',
            'Hugging Face',
            'OpenAI-kompatibel',
          ]),
        );
        expect(
          labels.toSet().length,
          labels.length,
          reason: 'keine doppelten Namen',
        );
        expect(
          LanguageModelProvider.values
              .map((provider) => provider.id)
              .toSet()
              .length,
          LanguageModelProvider.values.length,
        );
      },
    );

    testWidgets('zeigen ein eigenes Symbol', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              Builder(
                builder: (context) => providerLogo(
                  context,
                  provider: LanguageModelProvider.abacus,
                  size: 24,
                ),
              ),
              Builder(
                builder: (context) => providerLogo(
                  context,
                  provider: LanguageModelProvider.huggingFace,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      );

      expect(find.byIcon(Icons.alt_route), findsOneWidget);
      expect(find.byIcon(SimpleIcons.huggingface), findsOneWidget);
    });
  });

  test('jeder Anbieter hat ein Symbol', () {
    for (final provider in LanguageModelProvider.values) {
      expect(providerIconData(provider), isA<IconData>(), reason: provider.id);
    }
  });

  group('ElevenLabs', () {
    test('ist ein reiner Sprachanbieter ohne eigene API-Adresse', () {
      const provider = LanguageModelProvider.elevenLabs;

      expect(provider.label, 'ElevenLabs');
      expect(provider.isSpeechOnly, isTrue);
      expect(provider.hasEndpoint, isFalse);
      expect(provider.requiresCustomBaseUrl, isFalse);
      expect(LanguageModelProvider.googleAi.hasEndpoint, isFalse);
      expect(LanguageModelProvider.openAiCompatible.hasEndpoint, isTrue);
    });

    test('Sprachmodelle werden am Namen oder am Anbieter erkannt', () {
      LanguageModel model(String modelId, [LanguageModelProvider? provider]) =>
          LanguageModel(
            id: modelId,
            name: modelId,
            modelId: modelId,
            provider: provider,
            supportsImageInput: false,
            supportsStructuredOutput: false,
            supportsImageGeneration: false,
          );

      for (final id in [
        'gemini-2.5-flash-preview-tts',
        'tts-1',
        'gpt-4o-mini-tts',
      ]) {
        expect(model(id).isSpeechModel, isTrue, reason: id);
      }
      for (final id in ['gpt-4o', 'gemini-2.5-flash', 'settings-model']) {
        expect(model(id).isSpeechModel, isFalse, reason: id);
      }
      expect(
        model('eleven_v3', LanguageModelProvider.elevenLabs).isSpeechModel,
        isTrue,
      );
    });
  });
}
