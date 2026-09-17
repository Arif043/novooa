import 'package:equatable/equatable.dart';

class DataRecord extends Equatable {
  const DataRecord({
    required this.id,
    required this.fields,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final Map<String, Object?> fields;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object> get props => [id, fields, createdAt, updatedAt];
}
