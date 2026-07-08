part of 'node_config.dart';

mixin FileAttachmentSupport<T extends NodeConfig> on NodeConfig {
  List<PromptAttachment> get attachments;

  T copyWithAttachments(List<PromptAttachment> attachments);

  T attachFile(PromptAttachment attachment) {
    if (attachments.any((current) => current.id == attachment.id)) {
      return copyWithAttachments(attachments);
    }
    return copyWithAttachments([...attachments, attachment]);
  }

  T detachFile(String attachmentId) {
    return copyWithAttachments(
      attachments
          .where((attachment) => attachment.id != attachmentId)
          .toList(growable: false),
    );
  }
}
