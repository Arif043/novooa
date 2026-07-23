import 'package:equatable/equatable.dart';

class KnowledgeNote extends Equatable {
  const KnowledgeNote({
    required this.id,
    required this.knowledgeBaseId,
    required this.title,
    required this.path,
    required this.content,
    required this.outgoingLinks,
    required this.updatedAt,
  });

  final String id;
  final String knowledgeBaseId;
  final String title;
  final String path;
  final String content;
  final List<String> outgoingLinks;
  final DateTime updatedAt;

  @override
  List<Object?> get props {
    return [
      id,
      knowledgeBaseId,
      title,
      path,
      content,
      outgoingLinks,
      updatedAt,
    ];
  }

  KnowledgeNote copyWith({
    String? title,
    String? path,
    String? content,
    List<String>? outgoingLinks,
    DateTime? updatedAt,
  }) {
    return KnowledgeNote(
      id: id,
      knowledgeBaseId: knowledgeBaseId,
      title: title ?? this.title,
      path: path ?? this.path,
      content: content ?? this.content,
      outgoingLinks: outgoingLinks ?? this.outgoingLinks,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
