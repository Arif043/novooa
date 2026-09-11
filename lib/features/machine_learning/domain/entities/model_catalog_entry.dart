import 'package:equatable/equatable.dart';

class ModelCatalogEntry extends Equatable {
  const ModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.inputCount,
    required this.outputCount,
    required this.sizeBytes,
    required this.isManagedLocally,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final int inputCount;
  final int outputCount;
  final int sizeBytes;
  final bool isManagedLocally;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    tags,
    inputCount,
    outputCount,
    sizeBytes,
    isManagedLocally,
  ];
}
