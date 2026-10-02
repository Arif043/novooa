import 'package:syscat2/features/language_models/domain/entities/language_model.dart';
import 'package:syscat2/features/language_models/domain/entities/language_model_draft.dart';

/// Die Modelle eines Anbieters. `provider` ist `null` für Modelle, deren
/// Anbieter unbekannt ist.
class LanguageModelProviderGroup {
  const LanguageModelProviderGroup({
    required this.provider,
    required this.models,
  });

  final LanguageModelProvider? provider;
  final List<LanguageModel> models;

  String get label => provider?.label ?? 'Weitere Modelle';

  bool contains(String modelId) => models.any((model) => model.id == modelId);
}

/// Gruppiert Modelle nach Anbieter. Reihenfolge wie in
/// [LanguageModelProvider]; Modelle ohne bekannten Anbieter stehen zuletzt.
List<LanguageModelProviderGroup> groupModelsByProvider(
  List<LanguageModel> models,
) {
  return [
    for (final provider in [...LanguageModelProvider.values, null])
      if (_modelsOf(models, provider) case final matching
          when matching.isNotEmpty)
        LanguageModelProviderGroup(provider: provider, models: matching),
  ];
}

List<LanguageModel> _modelsOf(
  List<LanguageModel> models,
  LanguageModelProvider? provider,
) {
  return models.where((model) => model.provider == provider).toList();
}
