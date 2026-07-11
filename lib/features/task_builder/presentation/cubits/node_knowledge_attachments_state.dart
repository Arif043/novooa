import '../../domain/entities/knowledge_attachment.dart';

enum NodeKnowledgeAttachmentsStatus { loading, ready, failure }

class NodeKnowledgeAttachmentsState {
  const NodeKnowledgeAttachmentsState({
    this.status = NodeKnowledgeAttachmentsStatus.loading,
    this.notes = const [],
    this.message,
  });

  final NodeKnowledgeAttachmentsStatus status;
  final List<KnowledgeAttachment> notes;
  final String? message;
}
