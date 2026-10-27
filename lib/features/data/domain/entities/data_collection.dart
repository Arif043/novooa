import 'package:equatable/equatable.dart';

class DataCollection extends Equatable {
  const DataCollection({
    required this.name,
    required this.documentCount,
    required this.createdAt,
    required this.updatedAt,
    this.fields = const [],
    DateTime? changedAt,
  }) : changedAt = changedAt ?? updatedAt;

  final String name;
  final int documentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Felder der jüngsten Datensätze, alphabetisch — eine Vorschau, keine vollständige Liste.
  final List<String> fields;

  /// Letzte Änderung an der Sammlung oder einem ihrer Datensätze.
  final DateTime changedAt;

  @override
  List<Object> get props => [
    name,
    documentCount,
    createdAt,
    updatedAt,
    fields,
    changedAt,
  ];
}
