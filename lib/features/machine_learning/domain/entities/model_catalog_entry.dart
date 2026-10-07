import 'package:equatable/equatable.dart';

import 'model_manifest_input_parameter.dart';
import 'model_task.dart';

export 'model_manifest_input_parameter.dart';
export 'model_task.dart';

/// Herkunft eines lokal vorliegenden Modells.
enum ModelOrigin {
  /// Aus dem globalen Modellkatalog gecacht.
  catalog,

  /// Selbst importiert (Manifest + ONNX-Datei).
  import,
}

class ModelCatalogEntry extends Equatable {
  const ModelCatalogEntry({
    required this.id,
    required this.title,
    required this.description,
    this.translations = const {},
    this.task = ModelTask.other,
    this.languages = const [],
    required this.tags,
    required this.inputs,
    this.settings = const [],
    required this.outputs,
    required this.outputCount,
    required this.sizeBytes,
    this.origin,
  });

  final String id;
  final String title;
  final String description;

  /// Sprachcode (z. B. `en`, `pt-BR`) → Anzeigetexte; `title`/`description` sind die englische Rückfallsprache.
  final Map<String, ModelTranslation> translations;

  /// Das Problem, das das Modell löst; Grundlage der Filter-Chips in der Modellsuche.
  final ModelTask task;

  /// BCP-47-Codes; leer bei sprachunabhängigen Modellen.
  final List<String> languages;
  final List<String> tags;
  final List<ModelManifestInput> inputs;
  final List<ModelManifestSetting> settings;
  final List<ModelManifestOutput> outputs;
  final int outputCount;
  final int sizeBytes;

  /// `null`: Eintrag des globalen Katalogs, der lokal (noch) nicht vorliegt.
  final ModelOrigin? origin;

  /// Liegt in der Runtime vor — gecacht oder selbst importiert.
  bool get isManagedLocally => origin != null;
  bool get isCached => origin == ModelOrigin.catalog;
  bool get isImported => origin == ModelOrigin.import;

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    translations,
    task,
    languages,
    tags,
    inputs,
    settings,
    outputs,
    outputCount,
    sizeBytes,
    origin,
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
    return translations[normalized] ??
        translations[normalized.split('-').first];
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
