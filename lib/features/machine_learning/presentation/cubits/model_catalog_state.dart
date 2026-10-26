import '../../domain/entities/model_cache_status.dart';
import '../../domain/entities/model_catalog_entry.dart';
import '../../domain/entities/model_tag_vocabulary.dart';

enum ModelCatalogStatus { loading, ready, failure }

class ModelCatalogState {
  const ModelCatalogState({
    this.status = ModelCatalogStatus.loading,
    this.entries = const [],
    this.globalEntries = const [],
    this.globalStatus = ModelCatalogStatus.loading,
    this.cacheStatuses = const {},
    this.isSaving = false,
    this.message,
    this.tagVocabulary = ModelTagVocabulary.empty,
  });

  final ModelCatalogStatus status;

  /// Lokal vorliegende Modelle: gecacht oder selbst importiert.
  final List<ModelCatalogEntry> entries;
  final List<ModelCatalogEntry> globalEntries;
  final ModelCatalogStatus globalStatus;

  /// Modell-ID → laufender oder gescheiterter Download.
  final Map<String, ModelCacheStatus> cacheStatuses;
  final bool isSaving;
  final String? message;

  /// Bezeichnungen und Synonyme der Tags; leer, bis die Runtime es geliefert hat.
  final ModelTagVocabulary tagVocabulary;

  List<ModelCatalogEntry> get cachedEntries =>
      entries.where((entry) => entry.isCached).toList(growable: false);

  List<ModelCatalogEntry> get importedEntries =>
      entries.where((entry) => entry.isImported).toList(growable: false);

  ModelCatalogEntry? localEntry(String modelId) =>
      entries.where((entry) => entry.id == modelId).firstOrNull;

  /// Lokaler Eintrag vor dem globalen, damit Eigene Modelle mit gleicher ID gewinnen.
  ModelCatalogEntry? entryById(String modelId) =>
      localEntry(modelId) ??
      globalEntries.where((entry) => entry.id == modelId).firstOrNull;

  /// Globaler Katalog plus eigene Modelle; gecachte Einträge ersetzen ihren Katalogeintrag.
  List<ModelCatalogEntry> get selectableEntries => [
    ...entries,
    ...globalEntries.where((entry) => localEntry(entry.id) == null),
  ];

  ModelCatalogState copyWith({
    ModelCatalogStatus? status,
    List<ModelCatalogEntry>? entries,
    List<ModelCatalogEntry>? globalEntries,
    ModelCatalogStatus? globalStatus,
    Map<String, ModelCacheStatus>? cacheStatuses,
    bool? isSaving,
    String? message,
    bool clearMessage = false,
    ModelTagVocabulary? tagVocabulary,
  }) => ModelCatalogState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    globalEntries: globalEntries ?? this.globalEntries,
    globalStatus: globalStatus ?? this.globalStatus,
    cacheStatuses: cacheStatuses ?? this.cacheStatuses,
    isSaving: isSaving ?? this.isSaving,
    message: clearMessage ? null : message ?? this.message,
    tagVocabulary: tagVocabulary ?? this.tagVocabulary,
  );
}
