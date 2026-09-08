import '../../../language_models/domain/entities/language_model.dart';

enum NodeLanguageModelsStatus { loading, ready, failure }

class NodeLanguageModelsState {
  const NodeLanguageModelsState({
    this.status = NodeLanguageModelsStatus.loading,
    this.models = const [],
    this.message,
  });

  final NodeLanguageModelsStatus status;
  final List<LanguageModel> models;
  final String? message;
}
