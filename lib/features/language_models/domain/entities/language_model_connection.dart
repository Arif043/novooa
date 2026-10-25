import 'package:equatable/equatable.dart';

import 'language_model_provider.dart';

/// Eine verbundene Anbieter-Verbindung (Standalone). Ein Anbieter kann
/// mehrere [LanguageModel]s besitzen — siehe `LanguageModel.connectionId`.
class LanguageModelConnection extends Equatable {
  const LanguageModelConnection({
    required this.id,
    required this.name,
    required this.provider,
    this.baseUrl,
  });

  final String id;
  final String name;
  final LanguageModelProvider provider;
  final String? baseUrl;

  @override
  List<Object?> get props => [id, name, provider, baseUrl];
}
