import 'package:equatable/equatable.dart';

/// Welches bereits verbundene Sprachmodell als Vorgabe gilt — für
/// Sprachmodell-Bausteine ("Standardmodell verwenden") und für den
/// KI-Agenten. `null` heißt: kein Vorgabemodell gewählt, die bisherige
/// systemseitige Vorgabe bleibt aktiv.
class LanguageModelDefaults extends Equatable {
  const LanguageModelDefaults({this.blockModelId, this.assistantModelId});

  const LanguageModelDefaults.empty()
    : blockModelId = null,
      assistantModelId = null;

  final String? blockModelId;
  final String? assistantModelId;

  @override
  List<Object?> get props => [blockModelId, assistantModelId];
}
