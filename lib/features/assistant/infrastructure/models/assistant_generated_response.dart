import '../../domain/entities/assistant_url_source.dart';

class AssistantGeneratedResponse {
  const AssistantGeneratedResponse({
    required this.text,
    this.urlSources = const [],
  });

  final String text;
  final List<AssistantUrlSource> urlSources;
}
