class KnowledgeNoteDraft {
  const KnowledgeNoteDraft({
    required this.title,
    required this.path,
    required this.content,
    required this.outgoingLinks,
  });

  final String title;
  final String path;
  final String content;
  final List<String> outgoingLinks;
}
