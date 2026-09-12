import 'package:equatable/equatable.dart';

class ModelCatalogEntry extends Equatable {
  const ModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.inputs,
    required this.outputCount,
    required this.sizeBytes,
    required this.isManagedLocally,
  });

  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final List<ModelManifestInput> inputs;
  final int outputCount;
  final int sizeBytes;
  final bool isManagedLocally;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    tags,
    inputs,
    outputCount,
    sizeBytes,
    isManagedLocally,
  ];

  int get inputCount => inputs.length;
}

class ModelManifestInput extends Equatable {
  const ModelManifestInput({
    required this.name,
    required this.source,
    required this.dataType,
    required this.shape,
  });

  final String name;
  final ModelInputSource source;
  final String dataType;
  final List<Object> shape;

  @override
  List<Object?> get props => [name, source, dataType, shape];

  String get dataTypeLabel => '$dataType (${shape.join(' x ')})';
}

enum ModelInputSource {
  image,
  file,
  text,
  datetime,
  number,
  boolean,
  json,
  tensor,
}

extension ModelInputSourceLabel on ModelInputSource {
  String get label => switch (this) {
    .image => 'Bild',
    .file => 'Datei',
    .text => 'Text',
    .datetime => 'Datum und Uhrzeit',
    .number => 'Zahl',
    .boolean => 'Ja oder Nein',
    .json => 'Strukturierte Daten',
    .tensor => 'Tensor',
  };
}
