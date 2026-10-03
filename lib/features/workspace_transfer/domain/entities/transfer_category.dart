/// Bereiche, die exportiert und importiert werden können. Trigger fehlen
/// bewusst: Sie können an OAuth-Connectoren gebunden sein.
enum TransferCategory {
  files('files', 'Dateien & Ordner', 'Dateien'),
  data('data', 'Daten-Collections', 'Datensätze'),
  knowledge('knowledge', 'Wissensbasis', 'Notizen'),
  skills('skills', 'Fähigkeiten', 'Fähigkeiten'),
  employees('employees', 'Mitarbeiter', 'Mitarbeiter'),
  tasks('tasks', 'Aufgaben', 'Aufgaben');

  const TransferCategory(this.apiName, this.label, this.countLabel);

  final String apiName;
  final String label;
  final String countLabel;

  static TransferCategory? fromApiName(String value) {
    for (final category in values) {
      if (category.apiName == value) return category;
    }
    return null;
  }
}
