part of 'node_config.dart';

/// Mixin für NodeConfigs, die Fähigkeiten (Skills) tragen können. Analog zu
/// [FileAttachmentSupport] und [KnowledgeAttachmentSupport].
mixin SkillAttachmentSupport<T extends NodeConfig> on NodeConfig {
  List<SkillAttachment> get skillAttachments;

  T copyWithSkillAttachments(List<SkillAttachment> attachments);

  T attachSkill(SkillAttachment attachment) {
    if (skillAttachments.any((current) => current.id == attachment.id)) {
      return copyWithSkillAttachments(skillAttachments);
    }
    return copyWithSkillAttachments([...skillAttachments, attachment]);
  }

  T detachSkill(String attachmentId) {
    return copyWithSkillAttachments(
      skillAttachments
          .where((attachment) => attachment.id != attachmentId)
          .toList(growable: false),
    );
  }
}
