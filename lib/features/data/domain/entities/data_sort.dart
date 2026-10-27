import 'package:equatable/equatable.dart';

enum DataSortDirection {
  ascending('asc'),
  descending('desc');

  const DataSortDirection(this.wireName);

  final String wireName;
}

/// Sortierung der Datensätze nach einem Feld. Zahlen stehen vor Text, leere Werte immer am Ende
/// — die Runtime sortiert, damit auch Export und mehr als eine Seite dieselbe Ordnung haben.
class DataSort extends Equatable {
  const DataSort({required this.field, required this.direction});

  final String field;
  final DataSortDirection direction;

  /// Nur solche Felder kann die Runtime sortieren und filtern (keine Pfade, kein SQL).
  static bool isSortable(String field) =>
      RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]{0,63}$').hasMatch(field);

  /// Klick auf eine Spalte: aufsteigend → absteigend → ohne Sortierung.
  static DataSort? toggled(DataSort? current, String field) {
    if (current?.field != field) {
      return DataSort(field: field, direction: DataSortDirection.ascending);
    }
    return current!.direction == DataSortDirection.ascending
        ? DataSort(field: field, direction: DataSortDirection.descending)
        : null;
  }

  @override
  List<Object> get props => [field, direction];
}
