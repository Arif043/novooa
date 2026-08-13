import '../../domain/entities/assistant_url_source.dart';

class FirebaseAiAssistantResponse {
  const FirebaseAiAssistantResponse({
    required this.text,
    this.urlSources = const [],
  });

  final String text;
  final List<AssistantUrlSource> urlSources;
}
