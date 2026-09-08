import 'package:equatable/equatable.dart';

class LanguageModel extends Equatable {
  const LanguageModel({
    required this.id,
    required this.name,
    required this.modelId,
    required this.supportsImageInput,
    required this.supportsStructuredOutput,
    required this.supportsImageGeneration,
  });

  final String id;
  final String name;
  final String modelId;
  final bool supportsImageInput;
  final bool supportsStructuredOutput;
  final bool supportsImageGeneration;

  @override
  List<Object?> get props => [
    id,
    name,
    modelId,
    supportsImageInput,
    supportsStructuredOutput,
    supportsImageGeneration,
  ];
}
