import '../../domain/entities/model_catalog_entry.dart';

enum ModelCatalogStatus { loading, ready, failure }

class ModelCatalogState {
  const ModelCatalogState({
    this.status = ModelCatalogStatus.loading,
    this.entries = const [],
    this.globalEntries = const [],
    this.globalStatus = ModelCatalogStatus.loading,
    this.isSaving = false,
    this.message,
  });

  final ModelCatalogStatus status;
  final List<ModelCatalogEntry> entries;
  final List<ModelCatalogEntry> globalEntries;
  final ModelCatalogStatus globalStatus;
  final bool isSaving;
  final String? message;

  ModelCatalogState copyWith({
    ModelCatalogStatus? status,
    List<ModelCatalogEntry>? entries,
    List<ModelCatalogEntry>? globalEntries,
    ModelCatalogStatus? globalStatus,
    bool? isSaving,
    String? message,
    bool clearMessage = false,
  }) => ModelCatalogState(
    status: status ?? this.status,
    entries: entries ?? this.entries,
    globalEntries: globalEntries ?? this.globalEntries,
    globalStatus: globalStatus ?? this.globalStatus,
    isSaving: isSaving ?? this.isSaving,
    message: clearMessage ? null : message ?? this.message,
  );
}
