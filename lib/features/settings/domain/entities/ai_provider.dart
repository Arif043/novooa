enum AiProvider {
  openAi('openai', 'OpenAI'),
  googleAi('google_ai', 'Google AI'),
  anthropic('anthropic', 'Anthropic');

  const AiProvider(this.id, this.label);

  final String id;
  final String label;

  static AiProvider fromId(String id) {
    return AiProvider.values.firstWhere(
      (provider) => provider.id == id,
      orElse: () => AiProvider.googleAi,
    );
  }
}
