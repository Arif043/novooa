import 'package:equatable/equatable.dart';

import 'model_manifest_input_parameter.dart';

export 'model_manifest_input_parameter.dart';

class ModelCatalogEntry extends Equatable {
  const ModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    this.translations = const {},
    required this.tags,
    required this.inputs,
    this.settings = const [],
    required this.outputs,
    required this.outputCount,
    required this.sizeBytes,
    required this.isManagedLocally,
  });

  final String id;
  final String title;
  final String description;

  /// Sprachcode (z. B. `en`, `pt-BR`) → Anzeigetexte; `title`/`description` sind die englische Rückfallsprache.
  final Map<String, ModelTranslation> translations;
  final List<String> tags;
  final List<ModelManifestInput> inputs;
  final List<ModelManifestSetting> settings;
  final List<ModelManifestOutput> outputs;
  final int outputCount;
  final int sizeBytes;
  final bool isManagedLocally;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    translations,
    tags,
    inputs,
    settings,
    outputs,
    outputCount,
    sizeBytes,
    isManagedLocally,
  ];

  int get inputCount => inputs.length;

  String titleFor(String languageTag) =>
      _translationFor(languageTag)?.title ?? title;

  String descriptionFor(String languageTag) =>
      _translationFor(languageTag)?.description ?? description;

  List<String> tagsFor(String languageTag) =>
      _translationFor(languageTag)?.tags ?? tags;

  /// Exakter Treffer (`pt-BR`), danach nur die Sprache (`pt`), sonst keine Übersetzung.
  ModelTranslation? _translationFor(String languageTag) {
    final normalized = languageTag.replaceAll('_', '-');
    return translations[normalized] ?? translations[normalized.split('-').first];
  }
}

class ModelTranslation extends Equatable {
  const ModelTranslation({
    required this.title,
    required this.description,
    this.tags,
  });

  final String title;
  final String description;

  /// `null` übernimmt die Tags der Rückfallsprache.
  final List<String>? tags;

  @override
  List<Object?> get props => [title, description, tags];
}

class ModelManifestOutput extends Equatable {
  const ModelManifestOutput({
    required this.tensorName,
    required this.workflowName,
    required this.workflowType,
    required this.parameters,
  });

  final String tensorName;
  final String workflowName;
  final String workflowType;
  final List<ModelManifestOutputParameter> parameters;

  @override
  List<Object?> get props => [
    tensorName,
    workflowName,
    workflowType,
    parameters,
  ];

  String get workflowTypeLabel => switch (workflowType) {
    'string' => 'Text',
    'number' => 'Zahl',
    'boolean' => 'Ja oder Nein',
    'audio' => 'Audio',
    _ => 'Strukturierte Daten',
  };
}

class ModelManifestOutputParameter extends Equatable {
  const ModelManifestOutputParameter({
    required this.name,
    required this.label,
    required this.defaultValue,
    required this.minimum,
    required this.maximum,
  });

  final String name;
  final String label;
  final int defaultValue;
  final int minimum;
  final int maximum;

  @override
  List<Object?> get props => [name, label, defaultValue, minimum, maximum];
}

class ModelManifestInput extends Equatable {
  const ModelManifestInput({
    required this.name,
    required this.source,
    required this.dataType,
    required this.shape,
    this.requiresWorkflowMapping = true,
  });

  final String name;
  final ModelInputSource source;
  final String dataType;
  final List<Object> shape;
  final bool requiresWorkflowMapping;

  @override
  List<Object?> get props => [
    name,
    source,
    dataType,
    shape,
    requiresWorkflowMapping,
  ];

  String get dataTypeLabel => '$dataType (${shape.join(' x ')})';
}

enum ModelInputSource {
  image,
  audio,
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
    .audio => 'Audio',
    .file => 'Datei',
    .text => 'Text',
    .datetime => 'Datum und Uhrzeit',
    .number => 'Zahl',
    .boolean => 'Ja oder Nein',
    .json => 'Strukturierte Daten',
    .tensor => 'Tensor',
  };
}
