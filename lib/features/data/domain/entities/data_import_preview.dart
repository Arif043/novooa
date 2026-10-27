import 'package:equatable/equatable.dart';

/// Eine Spalte der Datei bekam einen anderen Feldnamen (z. B. „Kunden Name“ → „Kunden_Name“).
class DataFieldRename extends Equatable {
  const DataFieldRename({required this.from, required this.to});

  final String from;
  final String to;

  @override
  List<Object> get props => [from, to];
}

/// Was ein Import übernehmen würde. Mit Meldungen übernimmt die Runtime nichts.
class DataImportPreview extends Equatable {
  const DataImportPreview({
    required this.count,
    required this.fields,
    required this.renamedFields,
    required this.sample,
    required this.issues,
  });

  final int count;
  final List<String> fields;
  final List<DataFieldRename> renamedFields;
  final List<Map<String, Object?>> sample;
  final List<String> issues;

  bool get canImport => issues.isEmpty && count > 0;

  @override
  List<Object> get props => [count, fields, renamedFields, sample, issues];
}
