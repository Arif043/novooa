import 'ai_provider.dart';

class AiModelSettings {
  const AiModelSettings({
    required this.provider,
    required this.hasApiKey,
    required this.maskedApiKey,
    required this.updatedAt,
  });

  final AiProvider provider;
  final bool hasApiKey;
  final String maskedApiKey;
  final DateTime updatedAt;

  static AiModelSettings defaults() {
    return AiModelSettings(
      provider: AiProvider.googleAi,
      hasApiKey: false,
      maskedApiKey: '',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
