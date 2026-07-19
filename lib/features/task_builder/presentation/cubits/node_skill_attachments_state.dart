import '../../domain/entities/skill_attachment.dart';

enum NodeSkillAttachmentsStatus { loading, ready, failure }

class NodeSkillAttachmentsState {
  const NodeSkillAttachmentsState({
    this.status = NodeSkillAttachmentsStatus.loading,
    this.skills = const [],
    this.message,
  });

  final NodeSkillAttachmentsStatus status;
  final List<SkillAttachment> skills;
  final String? message;
}
