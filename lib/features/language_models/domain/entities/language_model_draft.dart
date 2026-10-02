enum LanguageModelProvider {
  googleAi('googleAi', 'Google AI'),
  xAi('xAi', 'xAI (Grok)', defaultBaseUrl: 'https://api.x.ai/v1'),
  mistral('mistral', 'Mistral AI', defaultBaseUrl: 'https://api.mistral.ai/v1'),
  openRouter(
    'openRouter',
    'OpenRouter',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
  ),
  abacus(
    'abacus',
    'Abacus.AI (RouteLLM)',
    defaultBaseUrl: 'https://routellm.abacus.ai/v1',
  ),
  huggingFace(
    'huggingFace',
    'Hugging Face',
    defaultBaseUrl: 'https://router.huggingface.co/v1',
  ),
  elevenLabs('elevenLabs', 'ElevenLabs'),
  ollama('ollama', 'Ollama (lokal)'),
  openAiCompatible('openAiCompatible', 'OpenAI-kompatibel');

  const LanguageModelProvider(this.id, this.label, {this.defaultBaseUrl});

  final String id;
  final String label;
  final String? defaultBaseUrl;

  bool get requiresCustomBaseUrl => this == openAiCompatible;

  /// Google AI und ElevenLabs sprechen über ihr SDK; eine API-Adresse wird
  /// weder abgefragt noch gesendet.
  bool get hasEndpoint => this != googleAi && this != elevenLabs;

  /// Der Anbieter bietet nur Sprachausgabe und keine Chat-Modelle.
  bool get isSpeechOnly => this == elevenLabs;

  /// Anbieter mit genau einem festen Endpunkt — im Gegensatz zu
  /// [openAiCompatible], das mehrfach mit unterschiedlichen Endpunkten
  /// verbunden werden kann und daher im Dropdown immer wählbar bleibt.
  bool get isDirectProvider => this != openAiCompatible;

  /// Wie [fromId], aber `null` statt Fehler — für Daten, in denen der Anbieter
  /// fehlen darf (ältere Modelle, Cloud-Dokumente ohne Anbieterangabe).
  static LanguageModelProvider? tryFromId(Object? id) {
    for (final provider in LanguageModelProvider.values) {
      if (provider.id == id) return provider;
    }
    return null;
  }

  static LanguageModelProvider fromId(String id) {
    return LanguageModelProvider.values.firstWhere(
      (provider) => provider.id == id,
      orElse: () => throw FormatException('Unbekannter Anbieter: $id'),
    );
  }
}

class LanguageModelDraft {
  const LanguageModelDraft({
    required this.connectionName,
    required this.provider,
    required this.baseUrl,
    required this.name,
    required this.modelId,
    required this.apiKey,
  });

  final String connectionName;
  final LanguageModelProvider provider;
  final String baseUrl;
  final String name;
  final String modelId;
  final String apiKey;
}
