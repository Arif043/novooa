import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';

import '../../domain/entities/employee.dart';

class EmployeeModel {
  const EmployeeModel({
    required this.id,
    required this.name,
    required this.role,
    required this.promptTemplate,
    required this.defaultSkills,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String role;
  final String promptTemplate;
  final List<SkillAttachment> defaultSkills;
  final DateTime updatedAt;

  factory EmployeeModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return EmployeeModel(
      id: snapshot.id,
      name: data['name'] as String? ?? snapshot.id,
      role: data['role'] as String? ?? '',
      promptTemplate: data['promptTemplate'] as String? ?? '',
      defaultSkills: _skillsFrom(data['defaultSkills']),
      updatedAt: _dateFrom(data['updatedAt']),
    );
  }

  Employee toDomain() {
    return Employee(
      id: id,
      name: name,
      role: role,
      promptTemplate: promptTemplate,
      defaultSkills: defaultSkills,
      updatedAt: updatedAt,
    );
  }

  static List<SkillAttachment> _skillsFrom(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((raw) {
          final entry = raw.map(
            (key, dynamic v) => MapEntry(key.toString(), v),
          );
          return SkillAttachment(
            name: entry['name'] as String? ?? '',
            description: entry['description'] as String? ?? '',
          );
        })
        .toList(growable: false);
  }

  static DateTime _dateFrom(Object? value) {
    if (value is Timestamp) return value.toDate();
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
