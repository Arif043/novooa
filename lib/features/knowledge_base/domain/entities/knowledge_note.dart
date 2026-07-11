import 'package:equatable/equatable.dart';

enum KnowledgeNoteType {
  atomic('Atomare Notiz'),
  moc('MOC'),
  unknown('Notiz');

  const KnowledgeNoteType(this.label);

  final String label;
}

class KnowledgeNote extends Equatable {
  const KnowledgeNote({
    required this.id,
    required this.knowledgeBaseId,
    required this.title,
    required this.path,
    required this.type,
    required this.outgoingLinks,
    required this.updatedAt,
  });

  final String id;
  final String knowledgeBaseId;
  final String title;
  final String path;
  final KnowledgeNoteType type;
  final List<String> outgoingLinks;
  final DateTime updatedAt;

  @override
  List<Object?> get props {
    return [id, knowledgeBaseId, title, path, type, outgoingLinks, updatedAt];
  }
}
