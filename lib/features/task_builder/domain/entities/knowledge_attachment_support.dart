part of 'node_config.dart';

mixin KnowledgeAttachmentSupport<T extends NodeConfig> on NodeConfig {
  List<KnowledgeAttachment> get knowledgeAttachments;

  T copyWithKnowledgeAttachments(List<KnowledgeAttachment> attachments);

  T attachKnowledge(KnowledgeAttachment attachment) {
    if (knowledgeAttachments.any((current) => current.id == attachment.id)) {
      return copyWithKnowledgeAttachments(knowledgeAttachments);
    }
    return copyWithKnowledgeAttachments([...knowledgeAttachments, attachment]);
  }

  T detachKnowledge(String attachmentId) {
    return copyWithKnowledgeAttachments(
      knowledgeAttachments
          .where((attachment) => attachment.id != attachmentId)
          .toList(growable: false),
    );
  }
}
