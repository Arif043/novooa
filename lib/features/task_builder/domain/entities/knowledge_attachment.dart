import 'package:equatable/equatable.dart';

class KnowledgeAttachment extends Equatable {
  const KnowledgeAttachment({
    required this.knowledgeBaseId,
    required this.noteId,
    required this.title,
    required this.path,
  });

  final String knowledgeBaseId;
  final String noteId;
  final String title;
  final String path;

  String get id => '$knowledgeBaseId:$noteId';

  @override
  List<Object?> get props => [knowledgeBaseId, noteId, title, path];
}
