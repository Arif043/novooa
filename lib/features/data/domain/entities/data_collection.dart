import 'package:equatable/equatable.dart';

class DataCollection extends Equatable {
  const DataCollection({
    required this.name,
    required this.documentCount,
    required this.createdAt,
    required this.updatedAt,
  });

  final String name;
  final int documentCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object> get props => [name, documentCount, createdAt, updatedAt];
}
