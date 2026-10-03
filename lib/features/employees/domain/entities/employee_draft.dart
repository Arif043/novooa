/// Eingabe beim Anlegen und Ändern eines Mitarbeiters.
class EmployeeDraft {
  const EmployeeDraft({
    required this.name,
    required this.constraint,
    this.skillNames = const [],
  });

  final String name;
  final String constraint;
  final List<String> skillNames;
}
