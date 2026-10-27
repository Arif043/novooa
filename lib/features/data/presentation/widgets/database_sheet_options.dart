import 'package:flutter/foundation.dart';

/// Auswahlspalte des Blatts: Zeilen über ihren Index, Kopf-Checkbox für alle sichtbaren.
class DatabaseSheetSelection {
  const DatabaseSheetSelection({
    required this.isSelected,
    required this.onToggleRow,
    required this.allSelected,
    required this.anySelected,
    required this.onToggleAll,
  });

  final bool Function(int row) isSelected;
  final ValueChanged<int> onToggleRow;
  final bool allSelected;
  final bool anySelected;
  final VoidCallback onToggleAll;
}

/// Sortierung über die Spaltenköpfe; nicht sortierbare Spalten bleiben ohne Klick.
class DatabaseSheetSort {
  const DatabaseSheetSort({
    required this.column,
    required this.ascending,
    required this.isSortable,
    required this.onSort,
  });

  /// Index der sortierten Spalte oder `null`.
  final int? column;
  final bool ascending;
  final bool Function(int column) isSortable;
  final ValueChanged<int> onSort;
}
