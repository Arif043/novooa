import 'package:equatable/equatable.dart';

import 'skill_attachment.dart';

/// Zuweisung eines Mitarbeiters (Subagent) an einen Baustein. 0..1 pro Node.
/// Enthält alle Daten, die der Executor braucht, ohne bei der Ausführung
/// nochmal Firestore aufzurufen — inklusive der Default-Skills des
/// Mitarbeiters, damit sie mit den node-lokalen Skills gemergt werden können.
class EmployeeAttachment extends Equatable {
  const EmployeeAttachment({
    required this.employeeId,
    required this.name,
    required this.role,
    required this.promptTemplate,
    required this.defaultSkills,
  });

  final String employeeId;
  final String name;
  final String role;
  final String promptTemplate;
  final List<SkillAttachment> defaultSkills;

  String get id => employeeId;

  @override
  List<Object?> get props => [
    employeeId,
    name,
    role,
    promptTemplate,
    defaultSkills,
  ];
}
