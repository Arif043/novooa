import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/skill.dart';

/// Firestore-Repräsentation eines Skills. Enthält nur Metadaten — der
/// SKILL.md-Inhalt liegt in Firebase Storage unter `storagePath`.
class SkillModel {
  const SkillModel({
    required this.id,
    required this.title,
    required this.description,
    required this.storagePath,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final String storagePath;
  final DateTime updatedAt;

  factory SkillModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return SkillModel(
      id: snapshot.id,
      title: data['title'] as String? ?? snapshot.id,
      description: data['description'] as String? ?? '',
      storagePath: data['storagePath'] as String? ?? '',
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  Skill toDomain({String content = ''}) {
    return Skill(
      id: id,
      title: title,
      description: description,
      storagePath: storagePath,
      content: content,
      updatedAt: updatedAt,
    );
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
