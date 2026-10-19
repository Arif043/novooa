part of 'node_config.dart';

/// Prüfung des Ergebnisses im Baustein „Teamarbeit“, bevor es abgegeben wird.
/// Sie hat ein eigenes Modell: Der Orchestrator kann günstig sein, die
/// Prüfung lohnt ein leistungsstärkeres.
class TeamworkReview extends Equatable {
  const TeamworkReview({this.enabled = true, this.languageModelId = ''});

  final bool enabled;

  /// Leer = Standardmodell.
  final String languageModelId;

  TeamworkReview copyWith({bool? enabled, String? languageModelId}) {
    return TeamworkReview(
      enabled: enabled ?? this.enabled,
      languageModelId: languageModelId ?? this.languageModelId,
    );
  }

  @override
  List<Object?> get props => [enabled, languageModelId];
}
