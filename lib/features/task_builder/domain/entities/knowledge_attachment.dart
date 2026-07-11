import 'package:equatable/equatable.dart';

enum KnowledgeAttachmentType { atomic, moc, unknown }

class KnowledgeAttachment extends Equatable {
  const KnowledgeAttachment({
    required this.knowledgeBaseId,
    required this.noteId,
    required this.title,
    required this.path,
    required this.type,
  });

  final String knowledgeBaseId;
  final String noteId;
  final String title;
  final String path;
  final KnowledgeAttachmentType type;

  String get id => '$knowledgeBaseId:$noteId';

  @override
  List<Object?> get props => [knowledgeBaseId, noteId, title, path, type];
}
