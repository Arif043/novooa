import 'language_model_provider.dart';

class LanguageModelConnectionDraft {
  const LanguageModelConnectionDraft({
    required this.provider,
    required this.baseUrl,
    required this.apiKey,
  });

  final LanguageModelProvider provider;
  final String baseUrl;
  final String apiKey;
}
