import 'package:syscat2/features/task_builder/domain/entities/skill_attachment.dart';

class EmployeeDraft {
  const EmployeeDraft({
    required this.name,
    required this.role,
    required this.promptTemplate,
    required this.defaultSkills,
  });

  final String name;
  final String role;
  final String promptTemplate;
  final List<SkillAttachment> defaultSkills;
}
