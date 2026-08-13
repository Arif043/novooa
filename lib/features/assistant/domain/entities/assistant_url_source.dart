enum AssistantUrlSourceStatus { retrieved, unavailable, paywalled, unsafe }

class AssistantUrlSource {
  const AssistantUrlSource({required this.url, required this.status});

  final Uri url;
  final AssistantUrlSourceStatus status;
}
