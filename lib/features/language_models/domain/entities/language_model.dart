import 'package:equatable/equatable.dart';

class LanguageModel extends Equatable {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.modelId,
    required this.supportsImageInput,
    required this.supportsStructuredOutput,
    required this.supportsImageGeneration,
    this.connectionId,
  });

  final String id;
  final String name;
  final String modelId;
  final bool supportsImageInput;
  final bool supportsStructuredOutput;
  final bool supportsImageGeneration;

  /// Nur in Standalone gesetzt — verweist auf die [LanguageModelConnection],
  /// über die dieses Modell verbunden wurde. Cloud kennt kein Connection-
  /// Konzept, daher optional statt eines erfundenen Platzhalterwerts.
  final String? connectionId;

  @override
  List<Object?> get props => [
    id,
    name,
    modelId,
    supportsImageInput,
    supportsStructuredOutput,
    supportsImageGeneration,
    connectionId,
  ];
}
