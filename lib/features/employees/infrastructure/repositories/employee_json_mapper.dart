import '../../domain/entities/employee.dart';
import '../../domain/entities/employee_draft.dart';

Employee employeeFromJson(Object? value) {
  if (value is! Map)
    throw const FormatException('Ein Mitarbeiter ist ungültig.');
  final skills = value['skills'];
  return Employee(
    id: value['id'] as String? ?? '',
    name: value['name'] as String? ?? '',
    constraint: value['constraint'] as String? ?? '',
    skillNames: skills is List
        ? skills.whereType<String>().toList(growable: false)
        : const [],
  );
}

List<Employee> employeesFromJson(Map<String, Object?> json) {
  final items = json['items'];
  if (items is! List) {
    throw const FormatException('Mitarbeiter konnten nicht gelesen werden.');
  }
  return items.map(employeeFromJson).toList(growable: false);
}

Map<String, Object?> employeeDraftToJson(EmployeeDraft draft) => {
  'name': draft.name,
  'constraint': draft.constraint,
  'skills': draft.skillNames,
};
