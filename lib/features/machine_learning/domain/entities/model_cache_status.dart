import 'package:equatable/equatable.dart';

enum ModelCacheState { downloading, failed }

/// Laufender oder gescheiterter Download eines Katalogmodells in die Runtime.
/// Ein fertig gecachtes Modell hat keinen Status mehr, es steht im lokalen Katalog.
class ModelCacheStatus extends Equatable {
  const ModelCacheStatus({
    required this.modelId,
    required this.state,
    this.message,
  });

  final String modelId;
  final ModelCacheState state;
  final String? message;

  bool get isDownloading => state == ModelCacheState.downloading;

  @override
  List<Object?> get props => [modelId, state, message];
}
