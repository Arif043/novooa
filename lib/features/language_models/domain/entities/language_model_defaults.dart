import 'package:equatable/equatable.dart';

/// Welche bereits verbundenen Sprachmodelle als Vorgabe gelten. `null` heißt
/// jeweils: nichts gewählt.
///
/// - [blockModelId]: für Sprachmodell-Bausteine ("Standardmodell verwenden");
///   ohne Wahl bleibt die systemseitige Vorgabe aktiv.
/// - [knowledgeAssistantModelId]: für den KI-Agenten der Wissensbasis in der
///   lokalen Runtime; ohne Wahl gilt [blockModelId]. Die Agenten der Cloud
///   nutzen das Modell, das die Cloud festlegt.
class LanguageModelDefaults extends Equatable {
  const LanguageModelDefaults({
    this.blockModelId,
    this.knowledgeAssistantModelId,
  });

  const LanguageModelDefaults.empty()
    : blockModelId = null,
      knowledgeAssistantModelId = null;

  final String? blockModelId;
  final String? knowledgeAssistantModelId;

  @override
  List<Object?> get props => [blockModelId, knowledgeAssistantModelId];
}
