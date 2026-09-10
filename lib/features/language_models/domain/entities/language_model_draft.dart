enum LanguageModelProvider {
  googleAi('googleAi', 'Google AI'),
  ollama('ollama', 'Ollama (lokal)'),
  openAiCompatible('openAiCompatible', 'OpenAI-kompatibel');

  const LanguageModelProvider(this.id, this.label);

  final String id;
  final String label;
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
