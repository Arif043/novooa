import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/knowledge_note.dart';

class KnowledgeNoteModel {
  const KnowledgeNoteModel({
    required this.id,
    required this.knowledgeBaseId,
    required this.title,
    required this.path,
    required this.content,
    required this.type,
    required this.outgoingLinks,
    required this.updatedAt,
  });

  final String id;
  final String knowledgeBaseId;
  final String title;
  final String path;
  final String content;
  final KnowledgeNoteType type;
  final List<String> outgoingLinks;
  final DateTime updatedAt;

  factory KnowledgeNoteModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return KnowledgeNoteModel(
      id: snapshot.id,
      knowledgeBaseId: data['knowledgeBaseId'] as String? ?? 'default',
      title: data['title'] as String? ?? snapshot.id,
      path: data['path'] as String? ?? '${snapshot.id}.md',
      content: data['content'] as String? ?? '',
      type: _typeFrom(data['type']),
      outgoingLinks: _stringListFrom(data['outgoingLinks']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  KnowledgeNote toDomain() {
    return KnowledgeNote(
      id: id,
      knowledgeBaseId: knowledgeBaseId,
      title: title,
      path: path,
      content: content,
      type: type,
      outgoingLinks: outgoingLinks,
      updatedAt: updatedAt,
    );
  }

  static KnowledgeNoteType _typeFrom(Object? value) {
    return KnowledgeNoteType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => KnowledgeNoteType.unknown,
    );
  }

  static List<String> _stringListFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<String>().toList(growable: false);
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
