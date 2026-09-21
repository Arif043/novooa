enum LanguageModelProvider {
  googleAi('googleAi', 'Google AI'),
  xAi('xAi', 'xAI (Grok)', defaultBaseUrl: 'https://api.x.ai/v1'),
  mistral('mistral', 'Mistral AI', defaultBaseUrl: 'https://api.mistral.ai/v1'),
  openRouter(
    'openRouter',
    'OpenRouter',
    defaultBaseUrl: 'https://openrouter.ai/api/v1',
  ),
  ollama('ollama', 'Ollama (lokal)'),
  openAiCompatible('openAiCompatible', 'OpenAI-kompatibel');

  const LanguageModelProvider(this.id, this.label, {this.defaultBaseUrl});

  final String id;
  final String label;
  final String? defaultBaseUrl;

  bool get requiresCustomBaseUrl => this == openAiCompatible;
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
